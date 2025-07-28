import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/participant.dart';
import '../domain/transaction.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/add_participant_bottom_sheet.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализируем ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeViewModel = context.read<HomeViewModel>();
      homeViewModel.loadParticipants();
      homeViewModel.loadTransactions();
    });
  }

  Future<void> _addParticipant() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddParticipantBottomSheet(),
    );

    if (name != null && name.isNotEmpty) {
      final viewModel = context.read<HomeViewModel>();
      await viewModel.addParticipant(name);
    }
  }

  Future<void> _addTransaction() async {
    final participants = context.read<HomeViewModel>().participants;
    final transaction = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(participants: participants),
    );

    if (transaction != null) {
      final viewModel = context.read<HomeViewModel>();
      await viewModel.addTransaction(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayMe'), centerTitle: true),
      body: Builder(
        builder: (context) {
          // Показываем ошибки
          final homeError = context.select<HomeViewModel, String?>((vm) => vm.error);
          if (homeError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(homeError),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(label: 'Скрыть', onPressed: () => context.read<HomeViewModel>().clearError()),
                ),
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Участники
                Builder(
                  builder: (context) {
                    final participants = context.select<HomeViewModel, List<Participant>>((vm) => vm.participants);
                    final isLoading = context.select<HomeViewModel, bool>((vm) => vm.isLoading);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Участники (${participants.length})',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (isLoading)
                          const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                        else if (participants.isEmpty)
                          SizedBox(
                            height: 100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 32, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text('Нет участников', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final participant = participants[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      participant.name.isNotEmpty ? participant.name : 'Без имени',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text('ID: ${participant.id}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteParticipant(participant)),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Транзакции
                Builder(
                  builder: (context) {
                    final transactions = context.select<HomeViewModel, List<Transaction>>((vm) => vm.transactions);
                    final isLoading = context.select<HomeViewModel, bool>((vm) => vm.isLoading);
                    final hasParticipants = context.select<HomeViewModel, bool>((vm) => vm.hasParticipants);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Транзакции (${transactions.length})',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (hasParticipants) IconButton(onPressed: _addTransaction, icon: const Icon(Icons.add), tooltip: 'Добавить транзакцию'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isLoading)
                          const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                        else if (!hasParticipants)
                          SizedBox(
                            height: 100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 32, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Сначала добавьте участников',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (transactions.isEmpty)
                          SizedBox(
                            height: 100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 32, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text('Нет транзакций', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Text('Добавьте первую транзакцию', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                final payer = context.read<HomeViewModel>().getPayerById(transaction.payerId);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: const Icon(Icons.receipt, color: Colors.white),
                                    ),
                                    title: Text(transaction.description ?? 'Без описания', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Плательщик: ${payer?.name ?? 'Неизвестно'}'),
                                        Text('Сумма: ${transaction.totalAmount.toStringAsFixed(2)} ₽'),
                                      ],
                                    ),
                                    trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteTransaction(transaction)),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final isLoading = context.select<HomeViewModel, bool>((vm) => vm.isLoading);
          return FloatingActionButton(onPressed: isLoading ? null : _addParticipant, child: const Icon(Icons.add));
        },
      ),
    );
  }

  Future<void> _deleteParticipant(Participant participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника'),
        content: Text('Вы уверены, что хотите удалить "${participant.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<HomeViewModel>();
      await viewModel.deleteParticipant(participant);
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить транзакцию'),
        content: Text('Вы уверены, что хотите удалить транзакцию "${transaction.description ?? 'Без описания'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<HomeViewModel>();
      await viewModel.deleteTransaction(transaction);
    }
  }
}
