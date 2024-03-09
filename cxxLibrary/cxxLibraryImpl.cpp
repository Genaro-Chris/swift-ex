#include "cxxLibraryHeader.h"
#include <concepts>
#include <iostream>
#include <random>
#include <functional>
#include <any>
#include <string>
using namespace std;

void hello_world(string msg) 
{
    cout << msg << endl;
}

float ConceptUser::Print(string msg) const
{
    cout << msg << " and self/this " << this->Msg << endl;
    return msg.length();
}

template <typename T>
void usesConcept(const T &value)
{
    cout << value << endl;
}

template <typename T>
    requires CxxExampleConcept<T>
void usesConcept(const T &value)
{
    value.Print("Inside func");
    usesConcept(value);
}

template <typename T>
    requires integral<T>
void usesConcept(const T &value)
{
    cout << "uses concept integral" << endl;
    usesConcept<decltype(value)>(value);
}

string returns_string()
{
    return "String from c++ land";
}

// Sometimes this is needed
template <>
void usesConcept(const ConceptUser &value)
{
    usesConcept(value);
}

// Sometimes this is needed
template <>
void usesConcept(const string &value)
{
    usesConcept(value);
}

template <CxxExampleConcept T>
void usesOnlyConcept(const T &value)
{
    cout << "usesOnlyConcept function" << endl;
    usesConcept(value);
}

void ex()
{
    // most times this is needed
    auto user = ConceptUser("ConceptUser");
    usesConcept<ConceptUser>(user);
    usesConcept<double>(0);
    usesConcept<int>(0);
    usesConcept<long>(0.0);
    usesConcept<string>("");
    special_move(user);
    usesOnlyConcept(user);
    auto type = SpecialType();
    special_move(type);
    double val = 1;
    special_move<double>(val);
}

const char *cxx_impl_exception::what() const noexcept
{
    return this->Msg.c_str();
}

void cxx_impl_exception::print()
{
    cout << this->Msg << endl;
}

cxx_impl_exception::~cxx_impl_exception()
{
    cout << "Destructor called" << endl;
}

void cxx_header::closure_taker(CBT body) const
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

template <typename T>
T &&special_move(T &x) noexcept
{
    string prefix = "type11 ";
    auto type_name = typeid(x).name();
    cout << "About to move value of type" << type_name << endl;
    return static_cast<T &&>(x);
}


template <>
any &&special_move(any &x) noexcept
{
    cout << "Called with any type" << endl;
    return special_move<any>(x);
}

/*
 template <>
SpecialType &&special_move(SpecialType &x) noexcept
{
    return special_move(x);
}

template <>
ConceptUser &&special_move(ConceptUser &x) noexcept
{
    return special_move(x);
} */

auto createUniformPseudoRandomNumberGenerator(double min, double max) -> double
{
    random_device seeder;                             // True random number generator to obtain a seed (slow)
    default_random_engine generator{seeder()};        // Efficient pseudo-random generator
    uniform_real_distribution distribution{min, max}; // Generate in [1, max) interval
    auto func = bind(distribution, generator);        //... and in the darkness bind them!
    return func();
}