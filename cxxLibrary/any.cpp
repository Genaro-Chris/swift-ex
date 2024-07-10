#include "any.h"
/*
#include <memory>
#include <optional>
#include <stdexcept>
#include <typeindex>
#include <typeinfo>

 Any::Any() : ptr{std::make_shared<BaseHolder>(BaseHolder())}, typeIndex{typeid(void)} {}

template <typename T>
Any::Any(T value) : ptr{std::make_shared<Holder<T>>(value)}, typeIndex{std::type_index(typeid(T))} {}

template <typename T>
auto Any::operator=(T value) -> Any &
{
    typeIndex = std::type_index(typeid(T));
    ptr = std::make_shared<Holder<T>>(value);
    return *this;
}

template <typename T>
[[nodiscard]]
auto Any::getValue() const -> T
{
    if (typeIndex != std::type_index(typeid(T)))
    {
        throw std::bad_cast();
    }
    auto holder = std::dynamic_pointer_cast<Holder<T>>(ptr);
    if (!holder)
    {
        throw std::bad_cast();
    }
    return holder->value;
} */

void ex1()
{
    // most times this is needed
    Any user = Any(12l);
    Any user_ = 12u;
    Any users = std::string{""};
}