#pragma once

#include <concepts>
#include <type_traits>
#include <atomic>

using namespace std;

class NonCopyableClass
{
protected:
    NonCopyableClass() = default;
    ~NonCopyableClass() = default; /// Protected non-virtual destructor
    NonCopyableClass(NonCopyableClass &&) = default;
    NonCopyableClass &operator=(NonCopyableClass &&) = default;
    NonCopyableClass(const NonCopyableClass &) = delete;
    NonCopyableClass &operator=(const NonCopyableClass &) = delete;
};

template <class Subclass>
class ReferenceCountedClass
{

public:
    ReferenceCountedClass() : referenceCount(1) {}
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
    ReferenceCountedClass(const ReferenceCountedClass &); // = delete;
    void operator=(const ReferenceCountedClass &);   // = delete;
    mutable atomic_int referenceCount;
};

// Concept for subclassing
template <typename BaseClass, typename SubClass>
concept SubClasser = common_reference_with<SubClass, BaseClass> || common_with<BaseClass, SubClass> || derived_from<SubClass, BaseClass> || convertible_to<BaseClass, SubClass> or convertible_to<BaseClass, SubClass> or same_as<BaseClass, SubClass>;

// For classes that directly subclass `ReferenceCountedClass` class or implement addref & delref methods
template <typename BaseClass, typename SubClass>
concept RetainAndReleaser = SubClasser<BaseClass, SubClass> or requires(const SubClass &ex) {
    {
        ex.addref()
    } -> std::same_as<void>;
    {
        ex.delref()
    } -> std::same_as<void>;
};

// Passed the base class that inherits from ReferenceCountedClass class
template <typename T>
    requires RetainAndReleaser<ReferenceCountedClass<T>, T>
inline void retained(T *_Nonnull ref)
{
    ref->addref();
}

// Passed the base class that inherits from ReferenceCountedClass class
template <typename T>
    requires RetainAndReleaser<ReferenceCountedClass<T>, T>
inline void released(T *_Nonnull ref)
{
    ref->delref();
}
