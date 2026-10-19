import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../state/vehicle_provider.dart';
import '../../repositories/firebase/firebase_contact_operations.dart';
import '../../repositories/firebase/firebase_contact_relation_repository.dart';
import '../../widgets/coming_soon_view.dart';

class ContactsScreenPlaceholder extends StatefulWidget {
  const ContactsScreenPlaceholder({super.key});
  @override
  State<ContactsScreenPlaceholder> createState() => _ContactsState();
}

class _ContactsState extends State<ContactsScreenPlaceholder> {
  Stream<Map<String, String>>? _stream;
  String? _vehicleId;
  String? _uid;
  String? _busy;
  String? _message;
  int _version = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<SessionProvider>().user?.id;
    final vehicleId = context.watch<VehicleProvider>().vehicle?.id;
    if (uid == _uid && vehicleId == _vehicleId) return;
    _uid = uid;
    _vehicleId = vehicleId;
    _version++;
    _busy = null;
    _message = null;
    final reader = context.read<VehicleContactsReader?>();
    _stream = uid != null && vehicleId != null && reader != null
        ? reader(vehicleId)
        : null;
  }

  Future<void> _revoke(String target) async {
    final version = _version;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revocar autorizaci\u00f3n'),
        content: const Text('Se retirar? el acceso de este contacto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (!mounted || version != _version || confirmed != true) return;
    setState(() {
      _busy = target;
      _message = null;
    });
    try {
      await context.read<FirebaseContactOperations>().revoke(
        _vehicleId!,
        target,
      );
    } catch (_) {
      if (mounted && version == _version) {
        setState(() => _message = 'No se pudo confirmar la revocaci\u00f3n.');
      }
    } finally {
      if (mounted && version == _version) {
        setState(() => _busy = null);
      }
    }
  }

  @override
  void dispose() {
    _version++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contactos de emergencia')),
    body: _stream == null
        ? const ComingSoonView(
            title: 'Contactos de emergencia',
            icon: Icons.contact_phone_outlined,
          )
        : StreamBuilder<Map<String, String>>(
            key: ValueKey('$_uid:$_vehicleId'),
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se pudieron consultar los contactos.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data!.entries.toList();
              return ListView(
                children: [
                  if (entries.isEmpty)
                    const ListTile(
                      title: Text('No hay contactos provisionados.'),
                    ),
                  for (var i = 0; i < entries.length; i++)
                    ListTile(
                      title: Text('Contacto ${i + 1}'),
                      subtitle: Text(entries[i].value),
                      trailing:
                          entries[i].value != 'revoked' &&
                              (context
                                      .read<FirebaseContactOperations?>()
                                      ?.available ??
                                  false)
                          ? TextButton(
                              onPressed: _busy != null
                                  ? null
                                  : () => _revoke(entries[i].key),
                              child: const Text('Revocar'),
                            )
                          : null,
                    ),
                  if (_message != null) ListTile(title: Text(_message!)),
                ],
              );
            },
          ),
  );
}
