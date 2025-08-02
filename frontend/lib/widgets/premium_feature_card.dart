import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isAvailable;
  final VoidCallback? onTap;

  const PremiumFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isAvailable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isAvailable ? 4 : 2,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isAvailable ? null : null,
            color: isAvailable ? null : Colors.grey[100],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable 
                        ? AppTheme.primaryColor 
                        : Colors.grey[400],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? null : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (!isAvailable)
                    Icon(
                      Icons.lock,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: isAvailable ? Colors.grey[700] : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumBenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isIncluded;

  const PremiumBenefitItem({
    super.key,
    required this.icon,
    required this.text,
    this.isIncluded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            color: isIncluded ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isIncluded ? null : Colors.grey[500],
                decoration: isIncluded ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}