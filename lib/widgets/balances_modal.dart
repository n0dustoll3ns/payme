import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';

class BalancesModal extends StatelessWidget {
  const BalancesModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            final participants = viewModel.participants;

            final balances = viewModel.balances;
            final debts = viewModel.debts;
            final totalAmount = viewModel.totalAmount;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Заголовок
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Детальные балансы', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),

                // Общая сумма
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.currency_ruble, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Общая сумма расходов', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                          Text(
                            '${totalAmount.toStringAsFixed(2)} ₽',
                            style: TextStyle(color: Colors.blue[700], fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Балансы участников
                Text('Балансы участников', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      final balance = balances[participant.id] ?? 0.0;
                      final isPositive = balance > 0.01;
                      final isNegative = balance < -0.01;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
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
                          title: Text(
                            participant.name.isNotEmpty ? participant.name : 'Без имени',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
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
                            '${balance.toStringAsFixed(2)} ₽',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? Colors.green[700]
                                  : isNegative
                                  ? Colors.red[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Долги между участниками
                if (debts.isNotEmpty) ...[
                  Text('Кто кому должен', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: debts.length,
                      itemBuilder: (context, index) {
                        final debt = debts[index];
                        final fromParticipant = participants.firstWhere((p) => p.id == debt.fromId);
                        final toParticipant = participants.firstWhere((p) => p.id == debt.toId);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
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
                          ),
                        );
                      },
                    ),
                  ),
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
                const SizedBox(height: 16),

                // Кнопка закрытия
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Закрыть', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
