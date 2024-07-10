#pragma once

#include "swift/bridging"
#include <iostream>

#define SWIFT_MOVE_ONLY __attribute__((swift_attr("@_moveOnly")))
#define ALWAYS_INLINE __attribute((always_inline))
#define SWIFT_CONSUMING __attribute__((swift_attr("consuming")))
#define SWIFT_BORROWING __attribute__((swift_attr("borrowing")))

struct SWIFT_NAME(NonCopyableType) MoveOnly
{
public:
    int getValue() const SWIFT_COMPUTED_PROPERTY;
    void setValue(int value) const SWIFT_COMPUTED_PROPERTY;
    MoveOnly();                            // Default constructor
    MoveOnly(int m_value);                 // constructor
    MoveOnly(const MoveOnly &sp) = delete; // Copy constructor
    MoveOnly(MoveOnly &&sp) noexcept;      // Move constructor
    ~MoveOnly();                           // Destructor (implicitly noexcept)

    MoveOnly &operator=(const MoveOnly &sp) = delete; // Copy assignment operator
    MoveOnly &operator=(MoveOnly &&sp) noexcept;      // Move assignment operator

    SWIFT_CONSUMING void consume_this() const; // consuming method

    SWIFT_BORROWING void borrow_this() const; // borrowing method

private:
    mutable int m_value;
} SWIFT_NONCOPYABLE;
