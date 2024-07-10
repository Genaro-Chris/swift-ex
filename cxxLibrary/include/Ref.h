#pragma once

#include <concepts>
#include <type_traits>
#include <atomic>

using namespace std;

class NonCopyableClass1
{
protected:
    NonCopyableClass1() = default;
    ~NonCopyableClass1() = default; /// Protected non-virtual destructor
    NonCopyableClass1(NonCopyableClass1 &&) = default;
    NonCopyableClass1 &operator=(NonCopyableClass1 &&) = default;
    NonCopyableClass1(const NonCopyableClass1 &) = delete;
    NonCopyableClass1 &operator=(const NonCopyableClass1 &) = delete;
};

template <class Subclass>
class ReferenceCountedClass1
{

public:
    ReferenceCountedClass1() : referenceCount(1) {}
    // NO virtual destructor!  Subclass should have a virtual destructor if it is not sealed.

    void addref() const { ++referenceCount; }
    void delref() const
    {
        if (delref_no_destroy())
            delete (Subclass *)this;
    }
    bool delref_no_destroy() const { return !--referenceCount; }
    int32_t debugGetReferenceCount() const { return referenceCount; } // Never use in production code, only for tracing
    bool isSoleOwner() const { return referenceCount == 1; }

private:
    ReferenceCountedClass1(const ReferenceCountedClass1 &); // = delete;
    void operator=(const ReferenceCountedClass1 &);   // = delete;
    mutable atomic_int referenceCount;
};

// Concept for subclassing
template <typename BaseClass, typename SubClass>
concept SubClasser1 = common_reference_with<SubClass, BaseClass> || common_with<BaseClass, SubClass> || derived_from<SubClass, BaseClass> || convertible_to<BaseClass, SubClass> or convertible_to<BaseClass, SubClass> or same_as<BaseClass, SubClass>;

// For classes that directly subclass `ReferenceCountedClass1` class or implement addref & delref methods
template <typename BaseClass, typename SubClass>
concept RetainAndReleaser1 = SubClasser1<BaseClass, SubClass> or requires(const SubClass &ex) {
    {
        ex.addref()
    } -> std::same_as<void>;
    {
        ex.delref()
    } -> std::same_as<void>;
};

// Passed the base class that inherits from ReferenceCountedClass1 class
template <typename T>
    requires RetainAndReleaser1<ReferenceCountedClass1<T>, T>
inline void retained_(T *_Nonnull ref)
{
    ref->addref();
}

// Passed the base class that inherits from ReferenceCountedClass1 class
template <typename T>
    requires RetainAndReleaser1<ReferenceCountedClass1<T>, T>
inline void released_(T *_Nonnull ref)
{
    ref->delref();
}
