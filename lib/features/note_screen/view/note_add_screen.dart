// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/note_model.dart';
import 'package:support_chat/providers/note_provider.dart';
import 'package:support_chat/services/gemini_service.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/utils/constants/theme.dart';

class NoteAddScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  const NoteAddScreen({super.key, this.note});

  @override
  ConsumerState<NoteAddScreen> createState() => _NoteAddScreenState();
}

class _NoteAddScreenState extends ConsumerState<NoteAddScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isSaved = false;
  bool _isAiProcessing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );
  }

  @override
  void dispose() {
    _saveNote();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_isSaved) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty && description.isEmpty) return;

    // Check if the content has changed
    if (widget.note != null &&
        widget.note!.title == title &&
        widget.note!.description == description) {
      return;
    }

    _isSaved = true;
    final noteService = ref.read(noteServiceProvider);

    if (widget.note == null) {
      await noteService.addNote(title, description);
    } else {
      await noteService.updateNote(widget.note!.id, title, description);
    }
  }

  /// Clean Markdown formatting from AI response
  String _cleanMarkdown(String text) {
    String cleaned = text;

    // Handle escaped characters first
    cleaned = cleaned.replaceAll(r'\$', r'$');
    cleaned = cleaned.replaceAll(r'\*', '*');
    cleaned = cleaned.replaceAll(r'\#', '#');

    // Remove LaTeX/Math notation delimiters ($$...$$, $...$, \(...\), \[...\])
    // Use non-greedy matching [\s\S]*? to handle multi-line blocks
    // Display math: $$formula$$ -> formula
    cleaned = cleaned.replaceAll(RegExp(r'\$\$([\s\S]*?)\$\$'), r'$1');
    // Inline math: $formula$ -> formula
    cleaned = cleaned.replaceAll(RegExp(r'\$([\s\S]*?)\$'), r'$1');
    // LaTeX brackets
    cleaned = cleaned.replaceAll(RegExp(r'\\\[([\s\S]*?)\\\]'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\\\(([\s\S]*?)\\\)'), r'$1');

    // Remove bold markdown (**text** or __text__)
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([\s\S]*?)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([\s\S]*?)__'), r'$1');

    // Remove italic markdown (*text* or _text_)
    cleaned = cleaned.replaceAll(RegExp(r'\*([\s\S]*?)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([\s\S]*?)_'), r'$1');

    // Convert headers (# Header) to plain text
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Remove code blocks (```code```)
    cleaned = cleaned.replaceAll(RegExp(r'```[a-z]*\s*[\s\S]*?```'), '');

    // Remove inline code (`code`)
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Remove links but keep text [text](url) -> text
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]*\)'), r'$1');

    // Handle bullet points
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[\*\-\+]\s+', multiLine: true),
      '• ',
    );

    // Handle numbered lists
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // Final pass to remove any remaining artifacts that are commonly left over
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*>\s*', multiLine: true),
      '',
    ); // Blockquotes

    // Clean up excessive newlines (more than 2)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }

  Future<void> _processWithAI(String action) async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty && action != 'generate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some content first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAiProcessing = true);

    try {
      final aiService = ref.read(geminiServiceProvider);
      String prompt = '';

      const systemInstruction =
          '\n\nIMPORTANT: Provide only the plain text content. Do not use Markdown (no asterisks, no hashtags), and do not use LaTeX math notation (no dollar signs). Use broad, clear, and professional language.';

      switch (action) {
        case 'improve':
          prompt =
              'Improve and enhance this note content while keeping the core message. Make it more clear, professional, and well-structured:\n\n$description$systemInstruction';
          break;
        case 'summarize':
          prompt =
              'Provide a concise summary of this note content:\n\n$description$systemInstruction';
          break;
        case 'grammar':
          prompt =
              'Fix all grammar, spelling, and punctuation errors in this text. Return only the corrected text:\n\n$description$systemInstruction';
          break;
        case 'expand':
          prompt =
              'Expand on these ideas with more details, examples, and explanations:\n\n$description$systemInstruction';
          break;
        case 'generate':
          final title = _titleController.text.trim();
          if (title.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a title/topic first!'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isAiProcessing = false);
            return;
          }
          prompt =
              'Generate detailed note content about: $title\n\nProvide comprehensive information, key points, and useful details.$systemInstruction';
          break;
      }

      final response = await aiService.getResponse(prompt);

      if (!mounted) return;

      if (response.startsWith('Error:') ||
          response.startsWith('Connection Error:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response), backgroundColor: Colors.red),
        );
      } else {
        // Clean markdown formatting before displaying
        final cleanedResponse = _cleanMarkdown(response);

        setState(() {
          _descriptionController.text = cleanedResponse;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI ${action == 'generate' ? 'generated' : 'processed'} successfully! ✨',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isAiProcessing = false);
      }
    }
  }

  void _showAiOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.fourthColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '✨ AI Assistant',
                  style: Theme.of(context).textTheme.titleLargePrimary,
                ),
                const SizedBox(height: 20),
                _buildAiOption(
                  icon: Icons.auto_fix_high,
                  title: 'Improve',
                  subtitle: 'Enhance and refine your note',
                  onTap: () {
                    Navigator.pop(context);
                    _processWithAI('improve');
                  },
                ),
                _buildAiOption(
                  icon: Icons.summarize,
                  title: 'Summarize',
                  subtitle: 'Create a concise summary',
                  onTap: () {
                    Navigator.pop(context);
                    _processWithAI('summarize');
                  },
                ),
                _buildAiOption(
                  icon: Icons.spellcheck,
                  title: 'Fix Grammar',
                  subtitle: 'Correct spelling and grammar',
                  onTap: () {
                    Navigator.pop(context);
                    _processWithAI('grammar');
                  },
                ),
                _buildAiOption(
                  icon: Icons.expand,
                  title: 'Expand',
                  subtitle: 'Add more details and context',
                  onTap: () {
                    Navigator.pop(context);
                    _processWithAI('expand');
                  },
                ),
                _buildAiOption(
                  icon: Icons.lightbulb,
                  title: 'Generate Content',
                  subtitle: 'Create content from title',
                  onTap: () {
                    Navigator.pop(context);
                    _processWithAI('generate');
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.fifthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.fifthColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.fifthColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.fifthColor, size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMediumPrimary,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmallSecondary,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.fifthColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _saveNote();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImage.appBg),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Text(
                        widget.note == null ? 'Add Note' : 'Edit Note',
                        style: Theme.of(context).textTheme.titleLargePrimary,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: _isAiProcessing
                              ? AppColors.tertiaryColor
                              : AppColors.fifthColor,
                        ),
                        onPressed: _isAiProcessing ? null : _showAiOptions,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note Title',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        color: AppColors.tertiaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isAiProcessing)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.fifthColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.fifthColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.fifthColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI is processing your note...',
                            style: Theme.of(context).textTheme.bodySmallPrimary
                                .copyWith(color: AppColors.fifthColor),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note Description',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.tertiaryColor,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
