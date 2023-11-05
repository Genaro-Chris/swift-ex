#include <algorithm>
#include <iostream>

// there isn't a way to include swift/bridging in c++ header file in linux yet

using namespace std;

void hello_world(string msg); //SWIFT_NAME(helloWorld(_:));

string returns_string();

template <typename T>
concept CxxExampleConcept = requires(const T &ex) {
    {
        ex.Print(string())
    } -> std::same_as<float>;
};

template <typename T>
void usesConcept(const T &value);

struct ConceptUser
{
private:
    string Msg;

public:
    ConceptUser(string msg) : Msg(msg){};
    float Print(string msg) const;
};

using CBT = void (*)();

class cxx_impl_exception
{
private:
    string Msg;

public:
    cxx_impl_exception(string msg) : Msg(msg){};
    ~cxx_impl_exception();
    void print();
    virtual const char *what() const noexcept;
}; // SWIFT_CONFORMS_TO_PROTOCOL(Swift.Error) SWIFT_SENDABLE;

struct cxx_header
{
    cxx_header() = default;
    ~cxx_header() = default;
    void closure_taker(CBT body) const;
};

class SpecialType
{
public:
    SpecialType() : m_value{1} {}                            // Default constructor
    SpecialType(int m_value) : m_value{m_value} {}           // constructor
    SpecialType(const SpecialType &sp) : m_value{sp.m_value} // Copy constructor
    {
        cout << "this copy cstor called" << endl;
    }

    SpecialType(SpecialType &&sp) noexcept : m_value{std::move(sp.m_value)} // Move constructor
    {
        cout << "this move cstor called" << endl;
    }
    ~SpecialType() {}                             // Destructor (implicitly noexcept)
    SpecialType &operator=(const SpecialType &sp) // Copy assignment operator
    {
        m_value = sp.m_value;
        return *this;
    }
    SpecialType &operator=(SpecialType &&sp) noexcept // Move assignment operator
    {
        m_value = std::move(sp.m_value);
        return *this;
    }

private:
    int m_value;
};

/// @brief  random number generator function
/// @param min min number it can randomly generate
/// @param max max number it can randomly generate
/// @return the generated random numbers
auto createUniformPseudoRandomNumberGenerator(double min, double max) -> double;

/// Special move function
///
/// Like the std::move function do, all this function do
/// is to convert a lvalue parameter into a rvalue return type
template <typename T>
T &&special_move(T &x) noexcept;

template <CxxExampleConcept T>
void usesOnlyConcept(const T &value);