const jsContent = `
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

    if (description === '' || isNaN(amount) || amount <= 0 || (type !== 'income' && type !== 'expense')) {
        alert('Proszę wprowadzić poprawny opis, dodatnią kwotę oraz wybrać typ transakcji.');
        return;
    }

    transactions.push({ description, amount, type });
    descriptionInput.value = '';
    amountInput.value = '';
    updateUI();
};

    const updateUI = () => {
        transactionList.innerHTML = '';
        let totalIncome = 0;
        let totalExpenses = 0;

        transactions.forEach((transaction) => {
            const li = document.createElement('li');
            li.textContent = `${transaction.description}: ${transaction.amount.toFixed(2)} PLN (${transaction.type})`;
            transactionList.appendChild(li);

            if (transaction.type === 'income') {
                totalIncome += transaction.amount;
            } else if (transaction.type === 'expense') {
                totalExpenses += transaction.amount;
            }
        });

        totalIncomeElement.textContent = totalIncome.toFixed(2);
        totalExpensesElement.textContent = totalExpenses.toFixed(2);
        netBalanceElement.textContent = (totalIncome - totalExpenses).toFixed(2);
    };

    addButton.addEventListener('click', addTransaction);
});
`;

module.exports = { htmlContent, cssContent, jsContent };