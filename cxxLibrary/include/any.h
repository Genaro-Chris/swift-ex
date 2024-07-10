#ifndef HOME_GENARO_PROJECTS_CPP_ANY_H
#define HOME_GENARO_PROJECTS_CPP_ANY_H

#include <any>
#include <memory>

#include <swift/bridging>
#include <typeindex>
#include <typeinfo>


/* class SWIFT_NAME(CXX_Any) Any
{
public:
    Any() = default;

    template <typename T>
    Any(T value) : ptr{std::make_shared<Holder<T>>(value)}, typeIndex{std::type_index(typeid(T))} {}

    template <typename T>
    auto operator=(T value) -> Any &
    {
        typeIndex = std::type_index(typeid(T));
        ptr = std::make_shared<Holder<T>>(value);
        return *this;
    }

    template <typename T>
    auto operator=(const T &value) -> Any &
    {
        typeIndex = std::type_index(typeid(T));
        ptr = std::make_shared<Holder<T>>(value);
        return *this;
    }

    template <typename T>
    [[nodiscard]]
    SWIFT_COMPUTED_PROPERTY auto getValue() const -> T
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
    }

    [[nodiscard]]
    SWIFT_COMPUTED_PROPERTY auto getValues() const
    {
        const std::type_info& info{typeid(typeIndex)};
        auto holder = std::dynamic_pointer_cast<Holder<std::any>>(ptr);
        if (!holder)
        {
            throw std::bad_cast();
        }
        return holder->value;
    }

private:
    struct BaseHolder
    {
        BaseHolder() = default;
        BaseHolder(const BaseHolder &) = default;
        BaseHolder(BaseHolder &&) = default;
        auto operator=(const BaseHolder &) -> BaseHolder & = default;
        auto operator=(BaseHolder &&) -> BaseHolder & = default;
        virtual ~BaseHolder() = default;
    } __attribute__((packed));

    template <typename T>
    struct alignas(alignof(T)) Holder : BaseHolder
    {
        explicit Holder(T value) : value{std::move(value)} {}
        T value;
    } __attribute__((aligned(alignof(T)), packed));

    std::shared_ptr<BaseHolder> ptr {std::make_shared<BaseHolder>(BaseHolder())};
    std::type_index typeIndex{typeid(void)};
}; */

#include <optional>

class SWIFT_NAME(CXX_Any) Any
{
public:
    Any() = default;

    template <typename T>
    Any(T value) : ptr{new T{value}}, typeIndex{std::type_index(typeid(T))} {}

    template <typename T>
    auto operator=(T &value) -> Any &
    {
        typeIndex = std::type_index(typeid(T));
        ptr = new T{value};
        return *this;
    }

    Any &operator=(const Any &value)
    {
        typeIndex = std::type_index(typeid(std::any));
        ptr = reinterpret_cast<std::any *>(value.ptr);
        return *this;
    }

    template <typename T>
    [[nodiscard]]
    auto getValue() const -> std::optional<T>
    {
        if (typeIndex != std::type_index(typeid(T)))
        {
            return nullptr;
        }
        auto holder = reinterpret_cast<T *>(ptr);
        if (!holder)
        {
            return nullptr;
        }
        return *holder;
    }

    [[nodiscard]]
    SWIFT_COMPUTED_PROPERTY auto getValues() const
    {
        const std::type_info &info{typeid(typeIndex)};
        auto holder = reinterpret_cast<std::any *>(ptr);
        if (!holder)
        {
            throw std::bad_cast();
        }
        return *holder;
    }

    ~Any()
    {
        delete reinterpret_cast<uint8_t *>(ptr);
    }

private:
    void *_Nullable ptr{nullptr};
    std::type_index typeIndex{typeid(void)};
};

#endif