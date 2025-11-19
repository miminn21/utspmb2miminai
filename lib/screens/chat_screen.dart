import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/ai_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF0A0E21)
          : const Color(0xFFF8FAFD),
      appBar: _buildAppBar(themeProvider),
      body: Column(
        children: [
          // Connection Status
          _buildConnectionStatus(themeProvider),

          // Chat Messages
          Expanded(
            child: Consumer<AIProvider>(
              builder: (context, provider, child) {
                final chatHistory = provider.chatHistory;

                if (chatHistory.isEmpty) {
                  return _buildWelcomeScreen(provider, themeProvider);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return Container(
                  decoration: BoxDecoration(
                    gradient: themeProvider.isDarkMode
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF0A0E21),
                              Color(0xFF1A1F35),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFF8FAFD),
                              Color(0xFFF0F4FF),
                            ],
                          ),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final chat = chatHistory[index];
                      return ChatBubble(
                        question: chat['question'] ?? '',
                        answer: chat['answer'] ?? '',
                        searchResults: chat['searchResults'] ?? [],
                        timestamp: chat['timestamp'] ?? DateTime.now(),
                        isUser: chat['isUser'] ?? false,
                        isLoading: chat['isLoading'] ?? false,
                        isError: chat['isError'] ?? false,
                        mathSolved: chat['mathSolved'] ?? false,
                        enhancedFeatures: chat['enhancedFeatures'] ?? false,
                        themeProvider: themeProvider,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (context.watch<AIProvider>().isLoading)
            _buildLoadingIndicator(themeProvider),

          // Input Section
          _buildInputSection(themeProvider),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: Animate(
        effects: [FadeEffect(duration: 800.ms), SlideEffect()],
        child: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: themeProvider.isDarkMode
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mimin AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'If I Can Learn, Why You Can\'t',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor:
          themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      actions: [
        Consumer<AIProvider>(
          builder: (context, provider, child) {
            return Animate(
              effects: [FadeEffect(duration: 1000.ms), ScaleEffect()],
              child: Row(
                children: [
                  // Connection Status Indicator
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: provider.backendConnected
                            ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                            : [
                                const Color(0xFFEF4444),
                                const Color(0xFFF87171)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: provider.backendConnected
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.backendConnected
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.backendConnected ? 'Online' : 'Offline',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Account Settings
                  _buildAccountMenu(themeProvider),
                  const SizedBox(width: 8),
                  // Clear Chat Button
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () {
                        _showClearChatDialog(themeProvider);
                      },
                      tooltip: 'Clear Chat',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountMenu(ThemeProvider themeProvider) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEC4899),
                  Color(0xFF8B5CF6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onSelected: (value) {
            if (value == 'profile') {
              _showUserProfile(themeProvider);
            } else if (value == 'theme') {
              _showThemeSelector(themeProvider);
            } else if (value == 'logout') {
              _showLogoutDialog(themeProvider);
            } else if (value == 'delete_account') {
              _showDeleteAccountDialog(themeProvider);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.purple[700],
                  ),
                  const SizedBox(width: 8),
                  Text(themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text('Logout'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete_account',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  const Text('Delete Account'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelector(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1F35),
                      Color(0xFF2D1B69),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFD),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: Colors.purple[700],
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose your preferred theme mode',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[700],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Light Mode Option
                _buildThemeOption(
                  theme: 'Light',
                  icon: Icons.light_mode,
                  color: Colors.amber,
                  isSelected: !themeProvider.isDarkMode,
                  onTap: () {
                    themeProvider.setDarkMode(false);
                    Navigator.pop(context);
                  },
                  themeProvider: themeProvider,
                ),
                const SizedBox(height: 12),

                // Dark Mode Option
                _buildThemeOption(
                  theme: 'Dark',
                  icon: Icons.dark_mode,
                  color: Colors.purple,
                  isSelected: themeProvider.isDarkMode,
                  onTap: () {
                    themeProvider.setDarkMode(true);
                    Navigator.pop(context);
                  },
                  themeProvider: themeProvider,
                ),

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String theme,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$theme Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme == 'Light'
                          ? 'Bright and clean appearance'
                          : 'Dark and comfortable for eyes',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserProfile(ThemeProvider themeProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1F35),
                      Color(0xFF2D1B69),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFD),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // User Info
                Text(
                  authProvider.currentUser?.name ?? 'Guest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  authProvider.currentUser?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Chats', '∞', Icons.chat, themeProvider),
                      _buildStatItem(
                          'Joined', 'Now', Icons.calendar_today, themeProvider),
                      _buildStatItem(
                          'Theme',
                          themeProvider.isDarkMode ? 'Dark' : 'Light',
                          Icons.palette,
                          themeProvider,
                          color: Colors.purple),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2)),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, ThemeProvider themeProvider,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1F35),
                      Color(0xFF2D1B69),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFD),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Logout Confirmation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[700],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2)),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _logoutUser();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFF87171),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: themeProvider.isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1F35),
                      Color(0xFF2D1B69),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFD),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.grey[700],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: themeProvider.isDarkMode
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2)),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _deleteUserAccount();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFDC2626),
                                Color(0xFFEF4444),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logoutUser() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    authProvider.logout();
    aiProvider.clearChat();

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logged out successfully'),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _deleteUserAccount() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final aiProvider = Provider.of<AIProvider>(context, listen: false);

    // Clear all data
    authProvider.logout(); // Sementara gunakan logout
    aiProvider.clearChat();

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account deleted successfully'),
        backgroundColor: Colors.blue[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ThemeProvider themeProvider) {
    return Consumer<AIProvider>(
      builder: (context, provider, child) {
        if (!provider.backendConnected || provider.hasError) {
          return Animate(
            effects: [FadeEffect(duration: 500.ms), SlideEffect()],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFFBEB),
                    Colors.orange[50]!,
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.orange[100]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange[500],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backend Connection Required',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ensure Python server is running on port 5000',
                              style: TextStyle(
                                color: Colors.orange[700]!,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Colors.orange[700], size: 18),
                        onPressed: () {
                          provider.retryConnection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checking backend connection...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.hasError)
                    Text(
                      'Error: ${provider.errorMessage}',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingIndicator(ThemeProvider themeProvider) {
    return Animate(
      effects: [FadeEffect(duration: 500.ms), ScaleEffect()],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(AIProvider provider, ThemeProvider themeProvider) {
    return Animate(
      effects: [FadeEffect(duration: 1000.ms)],
      child: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E21),
                    Color(0xFF1A1F35),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFD),
                    Color(0xFFF0F4FF),
                  ],
                ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated AI Icon
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(duration: 2000.ms, curve: Curves.easeInOut)
                        .then(delay: 500.ms)
                        .fadeOut(duration: 1000.ms),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome to Mimin AI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : const Color(0xFF1F2937),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                provider.backendConnected
                    ? '✅ Backend Connected\nAsk anything and get intelligent responses'
                    : '❌ Backend Disconnected\nPlease start Python server first',
                style: TextStyle(
                  fontSize: 16,
                  color: provider.backendConnected
                      ? (themeProvider.isDarkMode
                          ? Color(0xFF94A3B8)
                          : Colors.grey[600])
                      : Colors.orange[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Features Grid
              _buildFeaturesGrid(themeProvider),
              const SizedBox(height: 48),

              // Connection Troubleshooting
              if (!provider.backendConnected)
                _buildTroubleshootingSection(themeProvider),

              // Example Questions
              _buildExampleQuestions(themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(ThemeProvider themeProvider) {
    final features = [
      {'icon': Icons.search, 'title': 'Web Search', 'color': Colors.blue},
      {'icon': Icons.psychology, 'title': 'AI Powered', 'color': Colors.purple},
      {'icon': Icons.calculate, 'title': 'Math Solver', 'color': Colors.green},
      {
        'icon': Icons.lightbulb,
        'title': 'Smart Answers',
        'color': Colors.amber
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        final color = feature['color'] as Color;

        return Animate(
          effects: [FadeEffect(duration: 600.ms), ScaleEffect()],
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF1A1F35)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(themeProvider.isDarkMode ? 0.3 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTroubleshootingSection(ThemeProvider themeProvider) {
    return Animate(
      effects: [FadeEffect(duration: 800.ms), SlideEffect()],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Quick Setup Guide',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStepItem('1. Open terminal/CMD',
                'Navigate to your Python project folder'),
            _buildStepItem(
                '2. Install dependencies', 'Run: pip install flask flask-cors'),
            _buildStepItem('3. Start backend server', 'Run: python app.py'),
            _buildStepItem('4. Wait for success message',
                'Look for "Server started successfully!"'),
            _buildStepItem(
                '5. Refresh this app', 'Backend should connect automatically'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String step, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange[500],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestions(ThemeProvider themeProvider) {
    final examples = [
      {
        'question': 'Hitung luas lingkaran dengan jari-jari 7 cm',
        'icon': Icons.calculate,
        'color': Colors.green
      },
      {
        'question': 'Jelaskan tentang artificial intelligence',
        'icon': Icons.computer,
        'color': Colors.blue
      },
      {
        'question': 'Berita terbaru tentang teknologi',
        'icon': Icons.newspaper,
        'color': Colors.purple
      },
      {
        'question': 'Apa itu machine learning?',
        'icon': Icons.psychology,
        'color': Colors.orange
      },
    ];

    return Animate(
      effects: [FadeEffect(duration: 1200.ms)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try asking me:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...examples.map((example) {
            final color = example['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF1A1F35)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      example['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    example['question'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                  onTap: () {
                    _questionController.text = example['question'] as String;
                    _askQuestion();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeProvider themeProvider) {
    return Animate(
      effects: [FadeEffect(duration: 800.ms), SlideEffect()],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Consumer<AIProvider>(
          builder: (context, provider, child) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF0A0E21)
                          : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _questionController,
                      focusNode: _focusNode,
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black),
                      decoration: InputDecoration(
                        hintText: provider.backendConnected
                            ? 'Ask anything...'
                            : 'Start backend server first...',
                        hintStyle: TextStyle(
                          color: provider.backendConnected
                              ? (themeProvider.isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[500])
                              : Colors.orange[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: provider.backendConnected
                                ? (themeProvider.isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[500])
                                : Colors.grey[300],
                          ),
                          onPressed: provider.backendConnected
                              ? () {
                                  // Voice input functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Voice input coming soon!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _askQuestion(),
                      enabled: provider.backendConnected && !provider.isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: (provider.isLoading || !provider.backendConnected)
                        ? LinearGradient(
                            colors: [Colors.grey[400]!, Colors.grey[500]!])
                        : const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed:
                        (provider.isLoading || !provider.backendConnected)
                            ? null
                            : _askQuestion,
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    iconSize: 24,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showClearChatDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text('Clear Chat History',
                style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black)),
          ],
        ),
        content: Text(
            'Are you sure you want to clear all chat history? This action cannot be undone.',
            style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<AIProvider>(context, listen: false).clearChat();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _askQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    final provider = Provider.of<AIProvider>(context, listen: false);

    if (!provider.backendConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Backend not connected. Please start Python server first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    provider.askQuestion(question);
    _questionController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _questionController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class ChatBubble extends StatelessWidget {
  final String question;
  final String answer;
  final List<dynamic> searchResults;
  final DateTime timestamp;
  final bool isUser;
  final bool isLoading;
  final bool isError;
  final bool mathSolved;
  final bool enhancedFeatures;
  final ThemeProvider themeProvider;

  const ChatBubble({
    super.key,
    required this.question,
    required this.answer,
    required this.searchResults,
    required this.timestamp,
    required this.isUser,
    this.isLoading = false,
    this.isError = false,
    this.mathSolved = false,
    this.enhancedFeatures = false,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return _buildUserBubble();
    } else {
      return _buildAiBubble();
    }
  }

  Widget _buildUserBubble() {
    return Animate(
      effects: [FadeEffect(duration: 500.ms), SlideEffect()],
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1), width: 2),
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFF6366F1), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble() {
    return Animate(
      effects: [FadeEffect(duration: 500.ms), SlideEffect()],
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError
                      ? [Colors.red, Colors.red[300]!]
                      : mathSolved
                          ? [const Color(0xFF8B5CF6), const Color(0xFF6366F1)]
                          : [const Color(0xFF10B981), const Color(0xFF34D399)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline
                    : mathSolved
                        ? Icons.calculate
                        : Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF1A1F35)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(themeProvider.isDarkMode ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                      color: themeProvider.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isError
                                ? [Colors.red[50]!, Colors.red[100]!]
                                : mathSolved
                                    ? [
                                        const Color(0xFFF3E8FF),
                                        const Color(0xFFE9D5FF)
                                      ]
                                    : [
                                        const Color(0xFFF0F9FF),
                                        const Color(0xFFE0F2FE)
                                      ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isError
                                  ? Icons.error_outline
                                  : mathSolved
                                      ? Icons.calculate
                                      : Icons.auto_awesome_rounded,
                              color: isError
                                  ? Colors.red
                                  : mathSolved
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF0EA5E9),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isError
                                  ? 'Error Occurred'
                                  : mathSolved
                                      ? 'Mimin AI Math Solution'
                                      : 'Mimin AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isError
                                    ? Colors.red
                                    : mathSolved
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFF0EA5E9),
                                fontSize: 14,
                              ),
                            ),
                            if (mathSolved) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SOLVED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLoading)
                              _buildLoadingContent()
                            else
                              MarkdownBody(
                                data: answer.isNotEmpty
                                    ? answer
                                    : 'No response received from AI.',
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                  code: TextStyle(
                                    backgroundColor: themeProvider.isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    color: themeProvider.isDarkMode
                                        ? Colors.pink[300]
                                        : Colors.pink[700],
                                    fontSize: 13,
                                    fontFamily: 'Monospace',
                                  ),
                                  blockquote: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: themeProvider.isDarkMode
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF6B7280),
                                  ),
                                  h1: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  h2: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  h3: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                onTapLink: (text, href, title) {
                                  if (href != null) _launchURL(href);
                                },
                              ),

                            // Search Results
                            if (!isLoading && searchResults.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode
                                      ? const Color(0xFF0A0E21)
                                      : const Color(0xFFF8FAFD),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.search,
                                            size: 16,
                                            color: themeProvider.isDarkMode
                                                ? Colors.blue[300]
                                                : Colors.blue[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Sources & References',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...searchResults.map((result) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(8),
                                            leading: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.blue[900]
                                                    : Colors.blue[50],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.link,
                                                  size: 16,
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.blue[300]
                                                          : Colors.blue[700]),
                                            ),
                                            title: Text(
                                              result['title']?.toString() ??
                                                  'No Title',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              result['snippet']?.toString() ??
                                                  'No description',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600]),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () => _launchURL(
                                                result['url']?.toString() ??
                                                    ''),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Generating enhanced response...',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Searching web sources, analyzing with AI, and solving problems',
          style: TextStyle(
            fontSize: 12,
            color:
                themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _launchURL(String url) async {
    if (url.isEmpty || url == '#') return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('❌ Cannot launch URL: $url');
    }
  }
}
