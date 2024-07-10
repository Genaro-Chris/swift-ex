#include "moveonly.h"
#include <iostream>

using namespace std;

int MoveOnly::getValue() const { return m_value; }

void MoveOnly::setValue(int value) const { m_value = value; }

MoveOnly::MoveOnly() : m_value{0} {} // Default constructor

MoveOnly::MoveOnly(int m_value) : m_value{m_value} {} // constructor

MoveOnly::MoveOnly(MoveOnly &&sp) noexcept : m_value{std::move(sp.m_value)} // Move constructor
{
    cout << "MoveOnly move cstor" << endl;
}

MoveOnly::~MoveOnly() // Destructor (implicitly noexcept)
{
    cout << "MoveOnly destructor" << endl;
}

MoveOnly &MoveOnly::operator=(MoveOnly &&sp) noexcept // Move assignment operator
{
    cout << "MoveOnly move operator" << endl;
    m_value = std::move(sp.m_value);
    return *this;
}

void MoveOnly::consume_this() const // consuming method
{
    cout << "consuming this\n";
}

void MoveOnly::borrow_this() const // consuming method
{
    cout << "borrowing this\n";
}
