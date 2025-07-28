import 'package:flutter/material.dart';
import 'package:payme/domain/participant.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_transaction_view_model.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final List<Participant> participants;
  const AddTransactionBottomSheet({super.key, required this.participants});

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final Map<String, TextEditingController> _participantControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<AddTransactionViewModel>();
      viewModel.reset();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    for (final controller in _participantControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddTransactionViewModel(),
      child: Consumer<AddTransactionViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Заголовок
                        Row(
                          children: [
                            const Text('Добавить транзакцию', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Описание транзакции
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Описание (необязательно)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          onChanged: (value) => viewModel.setDescription(value),
                        ),
                        const SizedBox(height: 16),

                        // Выбор плательщика
                        DropdownButtonFormField<String>(
                          value: viewModel.selectedPayerId,
                          decoration: const InputDecoration(labelText: 'Кто платил? *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Выберите плательщика')),
                            ...widget.participants.map(
                              (participant) => DropdownMenuItem<String>(value: participant.id, child: Text(participant.name)),
                            ),
                          ],
                          onChanged: (value) => viewModel.setPayer(value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Выберите плательщика';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Общая сумма
                        TextFormField(
                          controller: _totalAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Общая сумма (₽) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            final amount = double.tryParse(value) ?? 0.0;
                            viewModel.setTotalAmount(amount);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите сумму';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Сумма должна быть больше 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Подсказка об отклонении суммы
                        if (viewModel.amountDeviation.abs() > 0.01)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: viewModel.amountDeviation.abs() < 0.1 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: viewModel.amountDeviation.abs() < 0.1 ? Colors.orange : Colors.red),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  viewModel.amountDeviation.abs() < 0.1 ? Icons.warning : Icons.error,
                                  color: viewModel.amountDeviation.abs() < 0.1 ? Colors.orange : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Отклонение: ${viewModel.amountDeviation > 0 ? '+' : ''}${viewModel.amountDeviation.toStringAsFixed(2)} ₽',
                                    style: TextStyle(
                                      color: viewModel.amountDeviation.abs() < 0.1 ? Colors.orange : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (viewModel.amountDeviation.abs() > 0.01) const SizedBox(height: 16),

                        // Суммы участников
                        const Text('Суммы участников:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final participants = widget.participants;

                            // Инициализируем контроллеры для участников
                            for (final participant in participants) {
                              if (!_participantControllers.containsKey(participant.id)) {
                                _participantControllers[participant.id] = TextEditingController();
                              }
                            }

                            return Column(
                              children: participants.map((participant) {
                                final controller = _participantControllers[participant.id]!;
                                final currentAmount = viewModel.participantAmounts[participant.id] ?? 0.0;

                                // Синхронизируем контроллер с моделью
                                if (controller.text.isEmpty && currentAmount > 0) {
                                  controller.text = currentAmount.toString();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: '${participant.name} (₽)',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.person_outline),
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (value) {
                                      final amount = double.tryParse(value) ?? 0.0;
                                      viewModel.setParticipantAmount(participant.id, amount);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Ошибка валидации
                        if (viewModel.error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(viewModel.error!, style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        if (viewModel.error != null) const SizedBox(height: 16),

                        // Кнопка добавления
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading ? null : () => _addTransaction(viewModel),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: viewModel.isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Добавить транзакцию', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _addTransaction(AddTransactionViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    viewModel.setLoading(true);

    final transaction = viewModel.createTransaction();
    if (transaction != null) {
      Navigator.of(context).pop(transaction);
    }

    viewModel.setLoading(false);
  }
}
