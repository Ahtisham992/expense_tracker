import 'package:flutter/material.dart';
import 'package:expense_track/model/expense.dart';
import 'package:expense_track/widget/expenses_list/expense_item.dart';

class Categories extends StatelessWidget {
  final List<Expense> expenses;
  final Category category;

  const Categories({
    super.key,
    required this.expenses,
    required this.category,
  });

  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.toString().split('.').last.toUpperCase()} Expenses',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rs${totalExpenses.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (ctx, index) => ExpenseItem(expenses[index]),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${category.toString().split('.').last.toUpperCase()} Expenses'),
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('Add Some Expenses.'))
          : mainContent,
    );
  }
}
