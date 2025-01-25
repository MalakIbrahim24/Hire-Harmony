import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hire_harmony/services/chat/cubit/chat_cubit.dart';

class ChatPage extends StatefulWidget {
  final String reciverEmail;

  const ChatPage({
    super.key,
    required this.reciverEmail,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ChatCubit>(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.reciverEmail),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  bloc: cubit,
                  buildWhen: (previous, current) =>
                      current is ChatSuccess || current is ChatFailure,
                  builder: (context, state) {
                    if (state is ChatSuccess) {
                      if (state.messages.isEmpty) {
                        return const Center(
                          child: Text('No messages'),
                        );
                      }
                      return ListView.builder(
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  message.senderPhotoUrl!,
                                ),
                                radius: 40,
                              ),
                              title: Text(message.message),
                              subtitle: Text(message.senderName),
                            );
                          });
                    } else if (state is ChatFailure) {
                      return Center(
                        child: Text(state.message),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Type a message',
                  suffixIcon: BlocConsumer<ChatCubit, ChatState>(
                      bloc: cubit,
                      listener: (context, state) {
                        if (state is ChatMessageSent) {
                          _messageController.clear();
                        }
                      },
                      listenWhen: (previous, current) =>
                          current is ChatMessageSent,
                      buildWhen: (previous, current) =>
                          current is ChatMessageSending ||
                          current is ChatMessageSent,
                      builder: (context, state) {
                        if (state is ChatMessageSending) {
                          return const CircularProgressIndicator();
                        }

                        return IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            await cubit.sendMessage(_messageController.text);
                          },
                        );
                      }),
                ),
              ),
            ],
          ),
        ));
  }
}
