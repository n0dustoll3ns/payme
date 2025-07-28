import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../domain/balance_calculator.dart';

class BalancesTab extends StatelessWidget {
  const BalancesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          final participants = viewModel.participants;
          final transactions = viewModel.transactions;
          final balances = viewModel.balances;
          final debts = viewModel.debts;
          final totalAmount = viewModel.totalAmount;
          final isLoading = viewModel.isLoading;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('Нет участников', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Добавьте участников для расчета балансов', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                ],
              ),
            );
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('Нет транзакций', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Добавьте транзакции для расчета балансов', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Общая статистика
              _buildSummaryCard(context, totalAmount, transactions.length, participants.length),
              const SizedBox(height: 16),

              // Балансы участников
              Text('Балансы участников', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBalancesList(context, participants, balances),
              const SizedBox(height: 16),

              // Долги между участниками
              if (debts.isNotEmpty) ...[
                Text('Кто кому должен', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDebtsList(context, participants, debts),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Все долги погашены!',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalAmount, int transactionsCount, int participantsCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Общая статистика', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem(context, 'Общая сумма', '${totalAmount.toStringAsFixed(2)} ₽', Icons.currency_ruble, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatItem(context, 'Транзакций', transactionsCount.toString(), Icons.receipt, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatItem(context, 'Участников', participantsCount.toString(), Icons.people, Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBalancesList(BuildContext context, List<dynamic> participants, Map<String, double> balances) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final participant = participants[index];
          final balance = balances[participant.id] ?? 0.0;
          final isPositive = balance > 0.01;
          final isNegative = balance < -0.01;
          final isZero = !isPositive && !isNegative;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive
                  ? Colors.green
                  : isNegative
                  ? Colors.red
                  : Colors.grey,
              child: Text(
                participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(participant.name.isNotEmpty ? participant.name : 'Без имени', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              isPositive
                  ? 'Должен получить'
                  : isNegative
                  ? 'Должен отдать'
                  : 'Баланс сведен',
              style: TextStyle(
                color: isPositive
                    ? Colors.green[700]
                    : isNegative
                    ? Colors.red[700]
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: Text(
              isZero ? '0.00 ₽' : '${balance.abs().toStringAsFixed(2)} ₽',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? Colors.green[700]
                    : isNegative
                    ? Colors.red[700]
                    : Colors.grey[600],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context, List<dynamic> participants, List<Debt> debts) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: debts.length,
        itemBuilder: (context, index) {
          final debt = debts[index];
          final fromParticipant = participants.firstWhere((p) => p.id == debt.fromId);
          final toParticipant = participants.firstWhere((p) => p.id == debt.toId);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
            ),
            title: Text('${fromParticipant.name} → ${toParticipant.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Перевод', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Text(
              '${debt.amount.toStringAsFixed(2)} ₽',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
          );
        },
      ),
    );
  }
}
