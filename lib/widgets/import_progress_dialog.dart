import 'package:flutter/material.dart';

class ImportProgressDialog extends StatefulWidget {
  final Future<void> Function(ImportProgressCallback callback) importFunction;
  final String title;
  final VoidCallback onComplete;

  const ImportProgressDialog({
    super.key,
    required this.importFunction,
    required this.title,
    required this.onComplete,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  late List<String> _messages;
  int _totalItems = 0;
  int _currentItem = 0;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messages = [];
    _startImport();
  }

  Future<void> _startImport() async {
    try {
      final callback = ImportProgressCallback(
        onProgress: (message, current, total) {
          if (mounted) {
            setState(() {
              _messages.add(message);
              _currentItem = current;
              _totalItems = total;
              
              // Limitar mensagens visíveis para performance
              if (_messages.length > 100) {
                _messages.removeAt(0);
              }
            });
          }
        },
      );

      await widget.importFunction(callback);

      if (mounted) {
        setState(() => _isCompleted = true);
        
        // Auto-close após 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          widget.onComplete();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalItems > 0 ? _currentItem / _totalItems : 0.0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final accentColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final containerBg = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100];

    return WillPopScope(
      onWillPop: () async => _isCompleted || _hasError,
      child: Dialog(
        insetAnimationDuration: const Duration(milliseconds: 300),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: accentColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hasError ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // Progress text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '$_currentItem / $_totalItems itens importados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Status messages with fixed height
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: containerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor ?? Colors.grey),
                  ),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final messageIndex = _messages.length - 1 - index;
                      final message = _messages[messageIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[400]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '❌ Erro durante importação:',
                        style: TextStyle(
                          color: isDarkMode ? Colors.red[300] : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Erro desconhecido',
                        style: TextStyle(
                          color: isDarkMode ? Colors.red[300] : Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_isCompleted && !_hasError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.green[900]?.withOpacity(0.3) : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[400]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: isDarkMode ? Colors.green[300] : Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Importação concluída com sucesso!',
                          style: TextStyle(
                            color: isDarkMode ? Colors.green[300] : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Botão de fechar/OK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: (_isCompleted || _hasError)
                          ? () {
                              widget.onComplete();
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        _isCompleted || _hasError ? 'OK' : 'Importando...',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImportProgressCallback {
  final void Function(String message, int current, int total) onProgress;

  ImportProgressCallback({
    required this.onProgress,
  });

  void report(String message, int current, int total) {
    onProgress(message, current, total);
  }
}
