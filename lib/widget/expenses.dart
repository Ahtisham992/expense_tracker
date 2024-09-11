import 'package:expense_track/widget/expenses_list/categories.dart';
import 'package:flutter/material.dart';
import 'package:expense_track/widget/chart/chart.dart';
import 'package:expense_track/widget/expenses_list/expenses_list.dart';
import 'package:expense_track/widget/new_expense.dart';
import 'package:expense_track/model/expense.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Expenses extends StatefulWidget {
  final void Function() onThemeChanged;
  final bool isDarkMode;

  const Expenses({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Expense> _registeredExpenses = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('grocery-list-c6490-default-rtdb.firebaseio.com',
        'expense-tracker.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data. Please try again later';
      });
    }
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
    }

    final Map<String, dynamic>? listData = json.decode(response.body);
    if (listData == null) {
      setState(() {
        _registeredExpenses = [];
        _isLoading = false;
      });
      return;
    }

    final List<Expense> loadedItems = [];
    for (final item in listData.entries) {
      final category = Category.values.firstWhere(
        (catItem) => catItem.name == item.value['category'],
      );

      loadedItems.add(
        Expense(
          id: item.key,
          title: item.value['title'],
          amount: item.value['amount'],
          date: DateTime.parse(item.value['date']),
          category: category,
        ),
      );
    }
    setState(() {
      _registeredExpenses = loadedItems;
      _isLoading = false;
    });
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    final url = Uri.https(
      'grocery-list-c6490-default-rtdb.firebaseio.com',
      'expense-tracker/${expense.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // If the delete request failed, add the item back to the list
      setState(() {
        _registeredExpenses.insert(expenseIndex, expense);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete the item.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: const Text('Expense deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final undoUrl = Uri.https(
                'grocery-list-c6490-default-rtdb.firebaseio.com',
                'expense-tracker/${expense.id}.json',
              );

              final response = await http.put(
                undoUrl,
                body: json.encode({
                  'title': expense.title,
                  'amount': expense.amount,
                  'date': expense.date.toIso8601String(),
                  'category': expense.category.name,
                }),
              );

              if (response.statusCode >= 400) {
                // If the re-insertion request failed, show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to undo the deletion.'),
                  ),
                );
              } else {
                // Re-add the item to the list if the re-insertion is successful
                setState(() {
                  _registeredExpenses.insert(expenseIndex, expense);
                });
              }
            },
          ),
        ),
      );
    }
  }

  void _openCategoryPage(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Categories(
          expenses: _registeredExpenses
              .where((expense) => expense.category == category)
              .toList(),
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Widget mainContent = Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('No expenses found. Start adding some!'),
    );

    if (_registeredExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    if (_error != null) {
      mainContent = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpenseTracker By Ahtisham'),
        actions: [
          IconButton(
            onPressed: widget.onThemeChanged,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _registeredExpenses),
                Expanded(
                  child: mainContent,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Chart(
                    expenses: _registeredExpenses,
                  ),
                ),
                Expanded(
                  child: mainContent,
                ),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Category.values.map((category) {
            final bucket =
                ExpenseBucket.forCategory(_registeredExpenses, category);
            return IconButton(
              icon: Icon(categoryIcons[category]),
              onPressed: () => _openCategoryPage(category),
              tooltip:
                  '${category.toString().split('.').last} - Rs${bucket.totalExpenses.toStringAsFixed(2)}',
            );
          }).toList(),
        ),
      ),
    );
  }
}
