import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/balances_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return HomeViewModel();
      },
      builder: (context, _) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('PayMe'),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'Участники'),
                  Tab(icon: Icon(Icons.receipt), text: 'Транзакции'),
                  Tab(icon: Icon(Icons.account_balance), text: 'Балансы'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Вкладка участников
                ParticipantsTab(),
                // Вкладка транзакций
                TransactionsTab(),
                // Вкладка балансов
                BalancesTab(),
              ],
            ),
            floatingActionButton: Builder(
              builder: (context) {
                final viewModel = context.read<HomeViewModel>();

                final isLoading = context.select<HomeViewModel, bool>((vm) => vm.isLoading);
                final hasParticipants = context.select<HomeViewModel, bool>((vm) => vm.hasParticipants);
                final hasTransactions = context.select<HomeViewModel, bool>((vm) => vm.transactions.isNotEmpty);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Кнопка для быстрого доступа к балансам
                    if (hasParticipants && hasTransactions)
                      FloatingActionButton(
                        onPressed: isLoading ? null : () => viewModel.showBalancesModal(context),
                        heroTag: 'show_balances',
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.account_balance_wallet),
                      ),
                    if (hasParticipants && hasTransactions) const SizedBox(width: 16),

                    // Кнопка добавления транзакции
                    if (hasParticipants)
                      FloatingActionButton(
                        onPressed: isLoading ? null : () => viewModel.showAddTransactionDialog(context),
                        heroTag: 'add_transaction',
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.receipt),
                      ),
                    if (hasParticipants) const SizedBox(width: 16),

                    // Кнопка добавления участника (только если нет транзакций)
                    if (!hasTransactions)
                      FloatingActionButton(
                        onPressed: isLoading ? null : () => viewModel.showAddParticipantDialog(context),
                        heroTag: 'add_participant',
                        child: const Icon(Icons.add),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class ParticipantsTab extends StatelessWidget {
  const ParticipantsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();

    final participants = context.watch<HomeViewModel>().participants;
    final isLoading = context.watch<HomeViewModel>().isLoading;
    final hasTransactions = context.watch<HomeViewModel>().transactions.isNotEmpty;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('Нет участников', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Добавьте первого участника', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Показываем предупреждение, если есть транзакции
          if (hasTransactions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Нельзя добавлять участников при наличии транзакций',
                      style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final hasTransactions = context.watch<HomeViewModel>().transactions.isNotEmpty;

                // Проверяем, участвует ли участник в транзакциях
                final isParticipantInTransactions =
                    hasTransactions &&
                    context.watch<HomeViewModel>().transactions.any(
                      (transaction) => transaction.payerId == participant.id || transaction.participantAmounts.containsKey(participant.id),
                    );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isParticipantInTransactions ? Colors.grey : Colors.blue,
                      child: Text(
                        participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      participant.name.isNotEmpty ? participant.name : 'Без имени',
                      style: TextStyle(fontWeight: FontWeight.w500, color: isParticipantInTransactions ? Colors.grey[600] : null),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${participant.id}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (isParticipantInTransactions)
                          Text(
                            'Участвует в транзакциях',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: isParticipantInTransactions ? Colors.grey[400] : null),
                      onPressed: isParticipantInTransactions ? null : () => viewModel.showDeleteParticipantDialog(context, participant),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Builder(
        builder: (context) => Consumer<HomeViewModel>(
          builder: (context, homeViewModel, child) {
            final transactions = homeViewModel.transactions;
            final isLoading = homeViewModel.isLoading;
            final hasParticipants = homeViewModel.hasParticipants;

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!hasParticipants) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('Сначала добавьте участников', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Для создания транзакций нужны участники', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                  ],
                ),
              );
            }

            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('Нет транзакций', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Добавьте первую транзакцию', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final payer = homeViewModel.getPayerById(transaction.payerId);
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
                      children: [Text('Плательщик: ${payer?.name ?? 'Неизвестно'}'), Text('Сумма: ${transaction.totalAmount.toStringAsFixed(2)} ₽')],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => homeViewModel.showDeleteTransactionDialog(context, transaction),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
