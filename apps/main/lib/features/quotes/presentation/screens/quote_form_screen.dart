import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../domain/entities/quote_entity.dart';
import '../quotes_notifier.dart';

/// Unified form screen for creating and editing quotes.
///
/// When [localId] is provided, the form loads the existing quote
/// data for editing. Otherwise, it shows a blank form for creation.
class QuoteFormScreen extends ConsumerStatefulWidget {
  const QuoteFormScreen({super.key, this.localId});

  /// If non-null, the form is in edit mode for this local quote ID.
  final int? localId;

  @override
  ConsumerState<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends ConsumerState<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _authorController;
  late final TextEditingController _sourceController;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLoaded = false;

  bool get _isEditMode => widget.localId != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _authorController = TextEditingController();
    _sourceController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _populateForm(QuoteEntity quote) {
    if (_isLoaded) return;
    _textController.text = quote.text;
    _authorController.text = quote.author;
    _sourceController.text = quote.source ?? '';
    _isActive = quote.isActive;
    _isLoaded = true;
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(quotesProvider.notifier);

    try {
      if (_isEditMode) {
        await notifier.editQuote(
          localId: widget.localId!,
          text: _textController.text.trim(),
          author: _authorController.text.trim(),
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          isActive: _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.quotesUpdateSuccess)),
          );
        }
      } else {
        await notifier.addQuote(
          text: _textController.text.trim(),
          author: _authorController.text.trim(),
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          isActive: _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.quotesSaveSuccess)),
          );
        }
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneral)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // If editing, populate form with existing data
    if (_isEditMode) {
      final quotesAsync = ref.watch(quotesProvider);
      quotesAsync.whenData((quotes) {
        final match = quotes.where((q) => q.localId == widget.localId).toList();
        if (match.isNotEmpty) _populateForm(match.first);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.quotesEdit : l10n.quotesCreate),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Quote icon header
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quote text (multiline)
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: l10n.quotesTextLabel,
                hintText: l10n.quotesTextHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.format_quote_outlined),
                ),
              ),
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return l10n.quotesTextValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Author
            TextFormField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: l10n.quotesAuthorLabel,
                hintText: l10n.quotesAuthorHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.quotesAuthorValidation;
                }
                if (value.trim().length > 255) {
                  return 'Max 255 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Source (optional)
            TextFormField(
              controller: _sourceController,
              decoration: InputDecoration(
                labelText: l10n.quotesSourceLabel,
                hintText: l10n.quotesSourceHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.book_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value != null && value.trim().length > 255) {
                  return 'Max 255 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Active toggle
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: SwitchListTile(
                title: Text(l10n.quotesIsActive),
                subtitle: Text(
                  _isActive
                      ? l10n.quotesFilterActive
                      : l10n.quotesFilterInactive,
                  style: TextStyle(
                    color:
                        _isActive ? Colors.green : colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Icon(
                  _isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _isActive ? Colors.green : colorScheme.error,
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveQuote,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(l10n.quotesSave),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
