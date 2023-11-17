#pragma once

#include <concepts>
#include <type_traits>

using namespace std;

class NonCopyable
{
protected:
    NonCopyable() = default;
    ~NonCopyable() = default; /// Protected non-virtual destructor
    NonCopyable(NonCopyable &&) = default;
    NonCopyable &operator=(NonCopyable &&) = default;
    NonCopyable(const NonCopyable &) = delete;
    NonCopyable &operator=(const NonCopyable &) = delete;
};

template <class Subclass>
class ReferenceCounted
{

public:
    ReferenceCounted() : referenceCount(0) {}
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
    ReferenceCounted(const ReferenceCounted &); // = delete;
    void operator=(const ReferenceCounted &);   // = delete;
    mutable int32_t referenceCount;
};

// Concept for subclassing
template <typename BaseClass, typename SubClass>
concept SubClasser = common_reference_with<SubClass, BaseClass> || common_with<BaseClass, SubClass> || derived_from<SubClass, BaseClass> || convertible_to<BaseClass, SubClass> or convertible_to<BaseClass, SubClass> or same_as<BaseClass, SubClass>;

// For classes that directly subclass `ReferenceCounted` class or implement addref & delref methods
template <typename BaseClass, typename SubClass>
concept RetainAndReleaser = SubClasser<BaseClass, SubClass> or requires(const SubClass &ex) {
    {
        ex.addref()
    } -> std::same_as<void>;
    {
        ex.delref()
    } -> std::same_as<void>;
};

// Passed the superclass that inherits from ReferenceCounted class
template <typename T>
    requires RetainAndReleaser<ReferenceCounted<T>, T>
inline void retained(T *_Nonnull ref)
{
    ref->addref();
}

// Passed the superclass that inherits from ReferenceCounted class
template <typename T>
    requires RetainAndReleaser<ReferenceCounted<T>, T>
inline void released(T *_Nonnull ref)
{
    ref->delref();
}
