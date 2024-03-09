#include "swift/bridging"

struct SWIFT_NAME(NonCopyableType) MoveOnly
{
public:
    int getValue() SWIFT_COMPUTED_PROPERTY;
    void setValue(int value) SWIFT_COMPUTED_PROPERTY;
    MoveOnly();                            // Default constructor
    MoveOnly(int m_value);                 // constructor
    MoveOnly(const MoveOnly &sp) = delete; // Copy constructor
    MoveOnly(MoveOnly &&sp) noexcept;      // Move constructor
    ~MoveOnly();                           // Destructor (implicitly noexcept)

    MoveOnly &operator=(const MoveOnly &sp) = delete; // Copy assignment operator
    MoveOnly &operator=(MoveOnly &&sp) noexcept;      // Move assignment operator
private:
    int m_value;
} SWIFT_NONCOPYABLE;
