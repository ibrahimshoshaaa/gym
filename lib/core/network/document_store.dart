import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'api_client.dart';
export 'api_client.dart' show DbTimestamp, ApiException;

/// REST-backed reads for the existing repository interfaces. All business writes
/// (subscriptions, attendance, debts, booking and points) use server commands.
class DocumentStore {
  static final instance = DocumentStore();
  final ApiClient api;
  DocumentStore({ApiClient? api}) : api = api ?? ApiClient.instance;
  CollectionReference<Map<String, dynamic>> collection(String path) => CollectionReference(this, path);
  DocumentReference<Map<String, dynamic>> doc(String path) => DocumentReference(this, path);
  Future<dynamic> command(String name, Map<String, dynamic> data) => api.request('POST', '/api/commands/$name', data);
}

Stream<T> watchApi<T>(ApiClient api, Future<T> Function() fetch, dynamic Function(T) serialize) {
  return Stream<T>.multi((controller) {
    var stopped = false;
    var busy = false;
    String? previous;
    Future<void> refresh() async {
      if (stopped || busy || !api.isForeground) return;
      busy = true;
      try {
        final value = await fetch();
        final signature = jsonEncode(encodeApiValue(serialize(value)));
        if (!stopped && signature != previous) {
          previous = signature;
          controller.add(value);
        }
      } catch (error, stack) {
        if (!stopped) controller.addError(error, stack);
        previous = null; // A recovered request must replace the previous error.
      } finally { busy = false; }
    }
    unawaited(refresh());
    final updates = api.changes.stream.listen((_) => refresh());
    final timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
    controller.onCancel = () { stopped = true; timer.cancel(); updates.cancel(); };
  });
}

class Query<T extends Map<String, dynamic>> {
  final DocumentStore store;
  final String path;
  final List<Map<String, dynamic>> filters;
  final Map<String, dynamic>? order;
  final int? maxResults;
  final List<dynamic>? start, end;
  Query(this.store, this.path, {this.filters = const [], this.order, this.maxResults, this.start, this.end});
  Query<T> where(String field, {dynamic isEqualTo, dynamic isGreaterThanOrEqualTo, dynamic isLessThanOrEqualTo, List<dynamic>? whereIn}) {
    final op = whereIn != null ? 'in' : isGreaterThanOrEqualTo != null ? 'gte' : isLessThanOrEqualTo != null ? 'lte' : 'eq';
    final value = whereIn ?? isGreaterThanOrEqualTo ?? isLessThanOrEqualTo ?? isEqualTo;
    return Query(store, path, filters: [...filters, {'field': field, 'op': op, 'value': value}], order: order, maxResults: maxResults, start: start, end: end);
  }
  Query<T> orderBy(String field, {bool descending = false}) => Query(store, path, filters: filters, order: {'field': field, 'descending': descending}, maxResults: maxResults, start: start, end: end);
  Query<T> limit(int count) => Query(store, path, filters: filters, order: order, maxResults: count, start: start, end: end);
  Query<T> startAt(List<dynamic> value) => Query(store, path, filters: filters, order: order, maxResults: maxResults, start: value, end: end);
  Query<T> endAt(List<dynamic> value) => Query(store, path, filters: filters, order: order, maxResults: maxResults, start: start, end: value);
  Future<QuerySnapshot<T>> get() async {
    final rows = await store.api.request('POST', '/api/data/query', {'path': path, 'filters': filters, if (order != null) 'order': order, if (maxResults != null) 'limit': maxResults, if (start != null) 'startAt': start, if (end != null) 'endAt': end}) as List<dynamic>;
    return QuerySnapshot(rows.map((row) => QueryDocumentSnapshot<T>(row['id'] as String, Map<String, dynamic>.from(row['data'] as Map) as T)).toList());
  }
  Stream<QuerySnapshot<T>> snapshots() => watchApi(store.api, get, (snap) => snap.docs.map((d) => {'id': d.id, 'data': d.data()}).toList());
}
class CollectionReference<T extends Map<String, dynamic>> extends Query<T> {
  CollectionReference(super.store, super.path);
  DocumentReference<T> doc([String? id]) => DocumentReference(store, '$path/${id ?? const Uuid().v4()}');
  Future<DocumentReference<T>> add(T data) async { final ref = doc(); await ref.set(data); return ref; }
}
class DocumentReference<T extends Map<String, dynamic>> {
  final DocumentStore store;
  final String path;
  DocumentReference(this.store, this.path);
  String get id => path.split('/').last;
  Future<DocumentSnapshot<T>> get() async {
    final row = await store.api.request('POST', '/api/data/read', {'path': path});
    return DocumentSnapshot(id, row == null ? null : Map<String, dynamic>.from(row['data'] as Map) as T);
  }
  Stream<DocumentSnapshot<T>> snapshots() => watchApi(store.api, get, (snap) => {'id': snap.id, 'data': snap.data()});
  Future<void> set(T data) async { await store.api.request('POST', '/api/data/write', {'path': path, 'operation': 'set', 'data': data}); }
  Future<void> update(Map<String, dynamic> data) async { await store.api.request('POST', '/api/data/write', {'path': path, 'operation': 'update', 'data': data}); }
  Future<void> delete() async { await store.api.request('POST', '/api/data/write', {'path': path, 'operation': 'delete'}); }
}
class DocumentSnapshot<T extends Map<String, dynamic>> {
  final String id;
  final T? _data;
  DocumentSnapshot(this.id, this._data);
  bool get exists => _data != null;
  T? data() => _data;
}
class QueryDocumentSnapshot<T extends Map<String, dynamic>> extends DocumentSnapshot<T> {
  QueryDocumentSnapshot(String id, T value) : super(id, value);
  @override
  T data() => super.data()!;
}
class QuerySnapshot<T extends Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<T>> docs;
  QuerySnapshot(this.docs);
}
