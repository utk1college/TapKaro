import 'package:flutter/material.dart';
import 'package:payment_app/utils/theme.dart';
import 'package:payment_app/utils/common_widgets.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: commonAppBar(title: 'TapKaro Rewards', context: context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? AppTheme.darkGradientColors 
                : AppTheme.gradientColors,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _RewardPoints(),
            const SizedBox(height: 24),
            Text(
              'Special Offers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Ensure visibility
              ),
            ),
            const SizedBox(height: 16),
            _OfferCard(
              title: 'Cashback Bonanza',
              description: '10% extra cashback on your next 3 transactions',
              color: Colors.purple.withOpacity(0.2),
              icon: Icons.currency_rupee,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _OfferCard(
              title: 'Referral Bonus',
              description: 'Get ₹100 for each friend you refer',
              color: Colors.blue.withOpacity(0.2),
              icon: Icons.people,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _OfferCard(
              title: 'Movie Tickets',
              description: 'Get 50% off on movie tickets',
              color: Colors.orange.withOpacity(0.2),
              icon: Icons.movie,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            Text(
              'Your Rewards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Ensure visibility
              ),
            ),
            const SizedBox(height: 16),
            const _RewardsList(),
          ],
        ),
      ),
    );
  }
}

class _RewardPoints extends StatelessWidget {
  const _RewardPoints();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '2,450',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'TapKaro Points',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          const Text(
            '550 points to next reward',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _OfferCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: isDarkMode 
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.15),
          width: isDarkMode ? 1 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.primaryColor, // Better contrast in light mode
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black87, // Better contrast in light mode
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.white70 : AppTheme.primaryColor, // Better contrast
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  const _RewardsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _RewardItem(
          icon: Icons.card_giftcard,
          title: 'Free Movie Ticket',
          subtitle: 'Expires in 15 days',
          points: '2000',
        ),
        _RewardItem(
          icon: Icons.fastfood,
          title: 'Food Coupon',
          subtitle: 'Expires in 7 days',
          points: '1500',
        ),
        _RewardItem(
          icon: Icons.local_taxi,
          title: 'Cab Discount',
          subtitle: 'Expires in 30 days',
          points: '1000',
        ),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String points;

  const _RewardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      color: isDarkMode 
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.15),
          width: isDarkMode ? 1 : 0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.15)
                : Colors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.white : Colors.purple,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : AppTheme.primaryColor, // Better contrast in light mode
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87, // Better contrast in light mode
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.15)
                : Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$points pts',
            style: TextStyle(
              color: isDarkMode ? Colors.white : AppTheme.primaryColor, // Better contrast in light mode
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
