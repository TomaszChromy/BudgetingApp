let transactions = [];

document.addEventListener('DOMContentLoaded', () => {
    const descriptionInput = document.getElementById('description');
    const amountInput = document.getElementById('amount');
    const transactionTypeSelect = document.getElementById('transaction-type');
    const addButton = document.getElementById('add-btn');
    const transactionList = document.getElementById('transaction-list');
    const totalIncomeElement = document.getElementById('total-income');
    const totalExpensesElement = document.getElementById('total-expenses');
    const netBalanceElement = document.getElementById('net-balance');

    if (!descriptionInput || !amountInput || !transactionTypeSelect || !addButton || !transactionList || !totalIncomeElement || !totalExpensesElement || !netBalanceElement) {
        console.error('One or more elements are missing in the DOM.');
        return;
    }

    const addTransaction = () => {
        const description = descriptionInput.value.trim();
        const amount = parseFloat(amountInput.value);
        const type = transactionTypeSelect.value;

        if (!validateTransaction(description, amount, type)) {
            alert('Proszę wprowadzić poprawny opis, dodatnią kwotę oraz wybrać typ transakcji.');
            return;
        }

        const transaction = { id: generateId(), description, amount, type };
        transactions.push(transaction);
        descriptionInput.value = '';
        amountInput.value = '';
        updateUI();
    };

    const validateTransaction = (description, amount, type) => {
        return (
            description !== '' &&
            !isNaN(amount) &&
            amount > 0 &&
            (type === 'income' || type === 'expense')
        );
    };

    const updateUI = () => {
        transactionList.innerHTML = '';
        let totalIncome = 0;
        let totalExpenses = 0;

        transactions.forEach((transaction) => {
            totalIncome += transaction.type === 'income' ? transaction.amount : 0;
            totalExpenses += transaction.type === 'expense' ? transaction.amount : 0;
            appendTransactionToList(transaction);
        });

        totalIncomeElement.textContent = formatCurrency(totalIncome);
        totalExpensesElement.textContent = formatCurrency(totalExpenses);
        netBalanceElement.textContent = formatCurrency(totalIncome - totalExpenses);
    };

    const appendTransactionToList = (transaction) => {
        const li = document.createElement('li');
        li.textContent = `${transaction.description}: ${formatCurrency(transaction.amount)} PLN (${transaction.type})`;
        transactionList.appendChild(li);
    };

    const formatCurrency = (value) => {
        return new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN' }).format(value);
    };

    const generateId = () => '_' + Math.random().toString(36).substr(2, 9);

    addButton.addEventListener('click', addTransaction);
});
