#include <algorithm>
#include <iostream>
#include <concepts>
#include <random>
#include <functional>
#include <string>
#include <swift/bridging>

using namespace std;

using TaskFuncPtr = void (*)();

#define SWIFT_MAIN_ACTOR __attribute__((swift_attr("@MainActor")))

SWIFT_MAIN_ACTOR void main_actor_func(void(*SWIFT_MAIN_ACTOR func));

inline void main_actor_func(void (*func)(void))
{
    cout << "About to run MainActor isolaied func closure in c++ ";
    func();
}

struct MainActorStruct
{
    string name;
    void print_name() const {
        cout << name + " ";
    }
} SWIFT_MAIN_ACTOR;


template <typename T>
concept CxxExampleConcept = requires(const T &ex) {
    {
        ex.Print(string())
    } -> std::same_as<float>;
};

template <typename T>
void usesConcept(const T &value)
{
    auto type_name = typeid(value).name();
    cout << "Called usesConcept function with instance of type " << type_name << endl;
}

struct __attribute__((swift_attr("@MainActor"))) ConceptUser
{
private:
    string Msg;

public:
    ConceptUser(string msg) : Msg(msg){};
    float Print(string msg) const
    {
        cout << msg << " and self/this " << this->Msg << endl;
        return msg.length();
    }
};

template <CxxExampleConcept T>
void usesOnlyConcept(const T &value)
{
    cout << "usesOnlyConcept function" << endl;
    usesConcept(value);
}

inline string returns_string()
{
    return "String from c++ land";
}

inline void hello_world(string msg)
{
    cout << msg << endl;
}

using CBT = void (*)();

class cxx_impl_exception;

class cxx_impl_exception
{
private:
    string Msg;

public:
    cxx_impl_exception(string msg) : Msg(msg){};
    ~cxx_impl_exception()
    {
        cout << "Destructor called" << endl;
    }
    void print()
    {
        cout << this->Msg << endl;
    }

    virtual const char *what() const noexcept
    {
        return this->Msg.c_str();
    }
};
SWIFT_CONFORMS_TO_PROTOCOL(Swift.Error)
SWIFT_UNCHECKED_SENDABLE;

struct cxx_header
{
    cxx_header() = default;
    ~cxx_header() = default;
    void closure_taker(CBT body) const
    {
        auto closure = [body]()
        {
            body();
        };
        auto clos = [=]() mutable noexcept(false) /* throw() */ -> int
        {
            body();
            throw cxx_impl_exception("Help");
            return 0;
        };
        try
        {
            closure();
            clos();
        }
        catch (const cxx_impl_exception &exp)
        {
            cerr << exp.what() << '\n';
        }
        catch (const exception &e)
        {
            cerr << e.what() << '\n';
        }
    }
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
inline auto createUniformPseudoRandomNumberGenerator(double min, double max) -> double
{
    random_device seeder;                             // True random number generator to obtain a seed (slow)
    default_random_engine generator{seeder()};        // Efficient pseudo-random generator
    uniform_real_distribution distribution{min, max}; // Generate in [1, max) interval
    auto func = bind(distribution, generator);        //... and in the darkness bind them!
    return func();
}

/// Special move function
///
/// Like the std::move function do, all this function do
/// is to convert a lvalue parameter into a rvalue return type
template <typename T>
inline T &&special_move(T &x) noexcept
{
    string prefix = "type11 ";
    auto type_name = typeid(x).name();
    cout << "About to move value of type" << type_name << endl;
    return static_cast<T &&>(x);
}

class CopyOnlyType
{
public:
    CopyOnlyType() : m_value{1} {}                             // Default constructor
    CopyOnlyType(int m_value) : m_value{m_value} {}            // constructor
    CopyOnlyType(const CopyOnlyType &sp) : m_value{sp.m_value} // Copy constructor
    {
        cout << "this copy cstor called" << endl;
    }

    CopyOnlyType(CopyOnlyType &&sp) noexcept = delete; // Move constructor
    ~CopyOnlyType()                                    // Destructor (implicitly noexcept)
    {
        cout << "this destructor" << endl;
    }
    CopyOnlyType &operator=(const CopyOnlyType &sp) // Copy assignment operator
    {
        m_value = sp.m_value;
        return *this;
    }
    CopyOnlyType &operator=(CopyOnlyType &&sp) noexcept = delete; // Move assignment operator

private:
    int m_value;
};

class MoveOnlyType_
{
public:
    MoveOnlyType_() : m_value{1} {}                                            // Default constructor
    MoveOnlyType_(int m_value) : m_value{m_value} {}                           // constructor
    MoveOnlyType_(const MoveOnlyType_ &sp) = delete;                            // Copy constructor
    MoveOnlyType_(MoveOnlyType_ &&sp) noexcept : m_value{std::move(sp.m_value)} // Move constructor
    {
        cout << "this move cstor called" << endl;
    }
    ~MoveOnlyType_() // Destructor (implicitly noexcept)
    {
        cout << "this destructor" << endl;
    }
    MoveOnlyType_ &operator=(const MoveOnlyType_ &sp) = delete; // Copy assignment operator
    MoveOnlyType_ &operator=(MoveOnlyType_ &&sp) noexcept       // Move assignment operator
    {
        m_value = std::move(sp.m_value);
        return *this;
    }

private:
    int m_value;
};