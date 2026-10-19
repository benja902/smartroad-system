import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../repositories/firebase/firebase_contact_operations.dart';
import '../../repositories/firebase/firebase_contact_relation_repository.dart';
import '../../state/access_context_provider.dart';
import '../../state/session_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/ghost_button.dart';

class PendingInvitationScreen extends StatefulWidget {
  const PendingInvitationScreen({super.key});

  @override
  State<PendingInvitationScreen> createState() =>
      _PendingInvitationScreenState();
}

class _PendingInvitationScreenState extends State<PendingInvitationScreen> {
  final _reference = TextEditingController();
  StreamSubscription<ContactRelationResolution>? _subscription;
  int _version = 0;
  bool _loading = false;
  bool _accepting = false;
  String? _relationStatus;
  bool _signingOut = false;
  String? _message;

  void _clear() {
    _version++;
    _subscription?.cancel();
    _subscription = null;
    _loading = false;
    _message = null;
    _relationStatus = null;
    _accepting = false;
  }

  void _lookup() {
    _clear();
    final reference = _reference.text.trim();
    if (reference.isEmpty) {
      setState(() => _message = 'Introduce la referencia de tu invitación.');
      return;
    }
    final version = _version;
    final uid = context.read<SessionProvider>().user?.id;
    if (uid == null ||
        context.read<AccessContextProvider>().status !=
            AccessStatus.restricted) {
      return;
    }
    setState(() => _loading = true);
    _subscription = context.read<ContactRelationReader>()(reference).listen(
      (result) {
        if (!mounted ||
            version != _version ||
            context.read<SessionProvider>().user?.id != uid) {
          return;
        }
        setState(() {
          _loading = result.loading;
          _relationStatus = result.status;
          _message = result.loading
              ? null
              : result.status == 'pending'
              ? 'Tienes una invitación pendiente. Todavía no concede acceso a datos.'
              : result.status == 'active'
              ? 'Relaci\u00f3n activa. La consulta de incidentes todav\u00eda no est\u00e1 disponible.'
              : result.status == 'revoked'
              ? 'La autorizaci\u00f3n fue revocada. No concede acceso a datos.'
              : 'No hay una invitación pendiente confirmada para esta referencia.';
        });
      },
      onError: (Object _) {
        if (!mounted ||
            version != _version ||
            context.read<SessionProvider>().user?.id != uid) {
          return;
        }
        setState(() {
          _loading = false;
          _relationStatus = null;
          _message =
              'No se pudo consultar la invitación. Puedes volver a intentarlo.';
        });
      },
    );
  }

  Future<void> _accept() async {
    final version = _version;
    final initialStatus = _relationStatus;
    final uid = context.read<SessionProvider>().user?.id;
    setState(() => _accepting = true);
    try {
      await context.read<FirebaseContactOperations>().accept(
        _reference.text.trim(),
      );
    } catch (_) {
      if (mounted &&
          version == _version &&
          _relationStatus == initialStatus &&
          context.read<SessionProvider>().user?.id == uid) {
        setState(
          () => _message = 'No se pudo confirmar la operaci\u00f3n. Puedes consultar de nuevo.',
        );
      }
    } finally {
      if (mounted &&
          version == _version &&
          context.read<SessionProvider>().user?.id == uid) {
        setState(() => _accepting = false);
      }
    }
  }

  Future<void> _signOut() async {
    _clear();
    setState(() => _signingOut = true);
    try {
      await context.read<SessionProvider>().signOut();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'No se pudo cerrar la sesión. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  void dispose() {
    _clear();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = context.watch<AccessContextProvider>();
    final loading = access.status == AccessStatus.loading;
    final failed = access.status == AccessStatus.error;
    if (access.status != AccessStatus.restricted && _subscription != null) {
      _clear();
      _reference.clear();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso a invitación'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.contentMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.edgeMargin),
              children: [
                if (loading) ...[
                  const LinearProgressIndicator(),
                  const Text('Comprobando tu relación de acceso…'),
                ] else if (failed) ...[
                  const Text(
                    'No se pudo comprobar tu acceso. No se han habilitado permisos.',
                  ),
                  if (context.read<SessionProvider>().user != null)
                    GhostButton(
                      label: 'Reintentar comprobación',
                      onPressed: access.retry,
                    ),
                ] else ...[
                  const Text(
                    'No hay una relación de propietario confirmada. Puedes consultar tu propia invitación.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _reference,
                    decoration: const InputDecoration(
                      labelText: 'Referencia de invitación',
                    ),
                    onChanged: (_) => setState(_clear),
                    onSubmitted: (_) => _lookup(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Consultar invitación',
                    onPressed: _loading ? null : _lookup,
                  ),
                  if (_loading) const LinearProgressIndicator(),
                ],
                if (_relationStatus == 'pending' &&
                    context.read<FirebaseContactOperations>().available)
                  PrimaryButton(
                    label: _accepting
                        ? 'Aceptando...'
                        : 'Aceptar invitaci\u00f3n',
                    onPressed: _accepting ? null : _accept,
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(_message!),
                  ),
                const SizedBox(height: AppSpacing.sm),
                GhostButton(
                  label: 'Cerrar sesión',
                  onPressed: _signingOut ? null : _signOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
