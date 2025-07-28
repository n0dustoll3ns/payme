import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/participant.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/add_participant_bottom_sheet.dart';

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
      context.read<HomeViewModel>().initialize();
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
      final success = await viewModel.addParticipant(name);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Участник "$name" добавлен'), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PayMe'), centerTitle: true),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          // Показываем ошибки
          if (viewModel.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.error!),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(label: 'Скрыть', onPressed: () => viewModel.clearError()),
                ),
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Участники (${viewModel.participants.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (viewModel.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (viewModel.participants.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text('Нет участников', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Добавьте первого участника', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.participants.length,
                      itemBuilder: (context, index) {
                        final participant = viewModel.participants[index];
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
            ),
          );
        },
      ),
      floatingActionButton: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton(onPressed: viewModel.isLoading ? null : _addParticipant, child: const Icon(Icons.add));
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
      final success = await viewModel.deleteParticipant(participant);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Участник "${participant.name}" удалён'), backgroundColor: Colors.red));
      }
    }
  }
}
