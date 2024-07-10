#include "AtomicShims.h"
#include "stdio.h"
#include <stdlib.h>

struct Plain
{
    char name[12];
};


typedef struct PlainCButOpaqueSwift
{
    int value;
} PlainCButOpaqueSwift;

PlainCButOpaqueSwift PlainCButOpaqueSwift_init()
{
    auto PlainCButOpaqueSwift obj = {.value = 12};
    return obj;
}

void take(struct PlainCButOpaqueSwift obj) {
    printf("%d", obj.value);
}

AtomicInt* AtomicInt_init(intptr_t value) {
    struct AtomicInt obj = {.value = value};
    struct AtomicInt * obj_ = malloc(sizeof(struct AtomicInt));
    *obj_ = obj;
    return obj_;
}

void AtomicInt_free(AtomicInt* value) {
    free(value);
}

void store(AtomicInt *atomic_value, intptr_t value)
{
    atomic_store_explicit(&atomic_value->value, value, __ATOMIC_RELAXED);
}

intptr_t load(AtomicInt *atomic_value)
{
    return atomic_load_explicit(&atomic_value->value, __ATOMIC_ACQUIRE);
}

intptr_t exchange(AtomicInt *atomic_value, intptr_t value)
{
    return atomic_exchange_explicit(&atomic_value->value, value, __ATOMIC_RELEASE);
}
