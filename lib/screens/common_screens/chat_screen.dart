import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatMessages = [
  {
  "role": "system",
  "content": """
  You are an HR assistant chatbot for an Attendance Management System. If the user's question matches any of the following, respond with the provided answers. Otherwise, use your general HR and app-related knowledge.

  Q: How can I apply for leave?
  A: Go to the 'Apply Leave' section under your dashboard, fill in the required details, and submit the request.

  Q: Where can I see my leave status?
  A: You can check your leave status under the 'My Leaves' section.

  Q: Can I apply for a half-day leave?
  A: Yes, half-day leave is allowed with proper justification and manager approval.

  Q: What happens if I miss check-in?
  A: If you miss check-in, your attendance will be marked absent unless updated by HR the same day.

  Q: How can I view my attendance?
  A: Go to the 'Attendance' card in your dashboard to view your daily attendance status.

  Q: How do I mark attendance?
  A: You can mark check-in and check-out from the 'Attendance' page during your shift hours.

  Q: How do I update or delete attendance?
  A: Only HR has access to update or delete attendance records through the Attendance Master page.

  Q: Where can I see company policies?
  A: Visit the 'Company Policies' section in your dashboard to view uploaded documents.

  Q: Can I update my profile information?
  A: Yes, you can update personal details like phone, address, and designation in the Profile section. Email and role are not editable.

  Q: What is the leave policy?
  A: Employees get 12 paid leaves per year. Leave requests must be approved by your reporting manager.

  Q: Can I work from home?
  A: Work-from-home requests must be officially approved by HR based on company guidelines.

  Q: How do I logout securely?
  A: Click the Logout button from the side menu or profile dropdown to log out securely.

  Q: How do I change the app theme?
  A: You can toggle between Light, Dark, and System themes in the Theme section under settings.

  Q: What happens if I forget to logout?
  A: You will be auto-logged out after inactivity for security reasons.

  Q: Who can manage employee records?
  A: Only HR has permission to add, edit, or delete employee records in the Employee Master section.

  Q: Why do we use Firebase in this app?
  A: Firebase provides a real-time backend with built-in authentication, secure Firestore database, and easy integration with Flutter.

  Q: Is my data secure in this app?
  A: Yes, Firebase enforces strict security rules, encrypted communication, and real-time access control to ensure your data is protected.

  Q: Can I see other employee profiles?
  A: No, employees can only view their own data. HR has access to all employee records.

  Q: Can HR approve or reject leave requests?
  A: Yes, HR can view, approve, or reject employee leave requests from the Leave Management panel.

  Q: What should I do if my attendance was marked wrong?
  A: Contact HR immediately to get it corrected the same day.
  """
}

];

  bool isLoading = false;

  Future<void> query(String prompt) async {
    final message = {
      "role": "user",
      "content": prompt,
    };

    setState(() {
      chatMessages.add(message);
      isLoading = true;
    });

    final data = {
      "model": "suvetha-ai",
      "messages": chatMessages,
      "stream": false,
    };

    try {
      final response = await http.post(
        Uri.parse("http://localhost:11434/api/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final botContent = responseData["message"]?["content"]?.toString();

        chatMessages.add({
          "role": "system",
          "content": botContent ?? "No response from model.",
        });
      } else {
        chatMessages.add({
          "role": "system",
          "content": "Error: Server returned status ${response.statusCode}",
        });
      }
    } catch (e) {
      chatMessages.add({
        "role": "system",
        "content": "Something went wrong: $e",
      });
    } finally {
      _controller.clear();
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildChatBubble(Map<String, String> message) {
    final isBot = message["role"] == 'system';
    final alignment =
    isBot ? Alignment.centerLeft : Alignment.centerRight;
    final color = isBot
        ? Colors.grey.shade300
        : Theme.of(context).colorScheme.primary;
    final icon = isBot ? Icons.smart_toy : Icons.person;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: isBot ? Colors.black87 : Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message["content"] ?? '',
                style: TextStyle(
                  color: isBot ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Llama Chat")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: chatMessages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) return const SizedBox.shrink();

                    if (index == chatMessages.length && isLoading) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final message = chatMessages[index];
                    return _buildChatBubble(message);
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: "Enter your prompt",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty && !isLoading) {
                        query(_controller.text.trim());
                      }
                    },
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
