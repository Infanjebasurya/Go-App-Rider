import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';
import 'package:goapp/features/help_support/presentation/cubit/emergency_contacts_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/safety_preference_cubit.dart';
import 'package:goapp/core/widgets/persistent_text_controller.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/features/auth/domain/services/phone_number_service.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SafetyPreferencesCubit>(),
      child: BlocBuilder<SafetyPreferencesCubit, SafetyPreferencesState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: const AppAppBar(
              title: 'Safety',
              titleStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.headingDark,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sharing Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: 'Automatic Status sharing',
                    subtitle: 'Keep Primary ones informed on every trip',
                    trailing: Switch(
                      value: state.autoShare,
                      onChanged: context
                          .read<SafetyPreferencesCubit>()
                          .setAutoShare,
                      inactiveThumbColor: AppColors.white,
                      inactiveTrackColor: AppColors.warmGray,
                      trackOutlineColor: const WidgetStatePropertyAll<Color>(
                        AppColors.transparent,
                      ),
                      trackOutlineWidth: const WidgetStatePropertyAll<double>(
                        0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.warmGray),
                  _SettingsTile(
                    title: 'Share at Night Your Location',
                    subtitle:
                        'Only active from 10 PM to 6 AM. Driver contact and live location will be shared your primary contact.',
                    trailing: Switch(
                      value: state.shareAtNight,
                      onChanged: context
                          .read<SafetyPreferencesCubit>()
                          .setShareAtNight,
                      inactiveThumbColor: AppColors.white,
                      inactiveTrackColor: AppColors.warmGray,
                      trackOutlineColor: const WidgetStatePropertyAll<Color>(
                        AppColors.transparent,
                      ),
                      trackOutlineWidth: const WidgetStatePropertyAll<double>(
                        0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.warmGray),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: 'Emergency Services Number',
                    subtitle: '911 (Default)',
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.black,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddEmergencyNumberPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class AddEmergencyNumberPage extends StatelessWidget {
  const AddEmergencyNumberPage({super.key});

  Future<void> _confirmDeleteContact(BuildContext context, int index) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.silver,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: AppColors.black,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Are you sure you want to Delete this contact?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.charcoal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AppButton(
                        label: 'Delete',
                        backgroundColor: AppColors.dangerDeep,
                        foregroundColor: AppColors.white,
                        borderRadius: 999,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AppButton(
                        label: 'Cancel',
                        backgroundColor: AppColors.warmGray,
                        foregroundColor: AppColors.charcoal,
                        borderRadius: 999,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<EmergencyContactsCubit>().deleteContact(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmergencyContactsCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: const AppAppBar(
              title: 'Add Emergency Number',
              titleStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.headingDark,
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose an emergency contact number for your trips. Driver contact and trip details will be shared with the selected contacts.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Alternative Configuration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _AppButton(
                      label: '+ Add contact',
                      onPressed: () async {
                        final contact =
                            await showModalBottomSheet<EmergencyContact?>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => const _AddContactSheet(),
                            );
                        if (contact == null || !context.mounted) return;
                        context.read<EmergencyContactsCubit>().addContact(
                          contact,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Added contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child:
                        BlocBuilder<
                          EmergencyContactsCubit,
                          EmergencyContactsState
                        >(
                          builder: (context, state) {
                            return _EmergencyContactsList(
                              items: state.contacts,
                              onMakePrimary: context
                                  .read<EmergencyContactsCubit>()
                                  .makePrimary,
                              onDelete: (index) =>
                                  _confirmDeleteContact(context, index),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyContactsList extends StatelessWidget {
  const _EmergencyContactsList({
    required this.items,
    required this.onMakePrimary,
    required this.onDelete,
  });

  final List<EmergencyContact> items;
  final ValueChanged<int> onMakePrimary;
  final ValueChanged<int> onDelete;

  Future<void> _showContactMenu(
    BuildContext context,
    GlobalKey anchorKey,
    int index,
  ) async {
    final RenderBox? button =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final Offset topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final action = await showMenu<_ContactMenuAction>(
      context: context,
      color: AppColors.white,
      elevation: 10,
      shadowColor: AppColors.black.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      position: RelativeRect.fromLTRB(
        topLeft.dx - 116,
        bottomRight.dy + 4,
        overlay.size.width - bottomRight.dx,
        overlay.size.height - topLeft.dy,
      ),
      items: const [
        PopupMenuItem(
          value: _ContactMenuAction.primary,
          height: 34,
          child: Text(
            'Set Primary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
        PopupMenuItem(
          value: _ContactMenuAction.delete,
          height: 34,
          child: Text(
            'Delete Contact',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );

    if (action == _ContactMenuAction.primary) {
      onMakePrimary(index);
      return;
    }
    if (action == _ContactMenuAction.delete) {
      onDelete(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final menuAnchorKey = GlobalKey();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.silver),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.sky,
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.sectionLabel,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isPrimary) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.number,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: menuAnchorKey,
                onPressed: () =>
                    _showContactMenu(context, menuAnchorKey, index),
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: AppColors.gray,
                ),
                splashRadius: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _ContactMenuAction { primary, delete }

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  late final PersistentTextController _nameController;
  late final PersistentTextController _relationController;
  late final PersistentTextController _numberController;
  final PhoneNumberService _phoneNumberService = PhoneNumberService();

  String? _nameError;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    _nameController = PersistentTextController(
      storageKey: 'safety.contact.name',
    );
    _relationController = PersistentTextController(
      storageKey: 'safety.contact.relation',
    );
    _numberController = PersistentTextController(
      storageKey: 'safety.contact.number',
    );
    _nameController.attach();
    _relationController.attach();
    _numberController.attach();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.silver,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Add contact',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Contact Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: _nameController,
              hint: 'Enter Name',
              leading: Icons.person_outline,
              errorText: _nameError,
              onChanged: (value) {
                if (_nameError == null) return;
                if (value.trim().isNotEmpty) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Who He/She?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: _relationController,
              hint: 'Who',
              leading: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            const Text(
              'Enter Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: _numberController,
              hint: 'Enter mobile number',
              leading: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              errorText: _numberError,
              onChanged: (value) {
                final digits = _phoneNumberService.normalizeDigits(value);
                final err = _phoneNumberService.validateIndiaMobile(
                  rawInput: value.trim(),
                  digits: digits,
                );
                setState(() => _numberError = err);
              },
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AppButton(
                    label: 'Cancel',
                    leading: const Icon(Icons.close_outlined, size: 18),
                    backgroundColor: AppColors.warmGray,
                    foregroundColor: AppColors.sectionLabel,
                    borderRadius: 999,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppButton(
                    label: 'Save',
                    leading: const Icon(Icons.save_outlined, size: 18),
                    borderRadius: 999,
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final rawNumber = _numberController.text.trim();
                      final digits = _phoneNumberService.normalizeDigits(
                        rawNumber,
                      );

                      final nameError = name.isEmpty ? 'Enter name' : null;
                      final numberError = _phoneNumberService
                          .validateIndiaMobile(
                            rawInput: rawNumber,
                            digits: digits,
                          );

                      if (nameError != null || numberError != null) {
                        setState(() {
                          _nameError = nameError;
                          _numberError = numberError;
                        });
                        return;
                      }

                      final displayNumber = '+91 $digits';
                      Navigator.of(context).pop(
                        EmergencyContact(
                          name: name,
                          number: displayNumber,
                          isPrimary: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    this.controller,
    required this.hint,
    required this.leading,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String hint;
  final IconData leading;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.white,
        prefixIcon: Icon(leading, size: 18, color: AppColors.sectionLabel),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutralDDD),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutralDDD),
        ),
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  const _AppButton({
    required this.label,
    this.leading,
    this.backgroundColor = AppColors.emerald,
    this.foregroundColor = AppColors.white,
    required this.onPressed,
    this.borderRadius = 12,
  });

  final String label;
  final Widget? leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShadowButton(
      onPressed: onPressed,
      icon: leading ?? const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
