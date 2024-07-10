#include <stdatomic.h>

// first
typedef struct AtomicInt
{
    atomic_intptr_t value;
} AtomicInt;

/* typedef struct
{
    atomic_intptr_t value;
} AtomicInt; */

/* struct AtomicInt
{
    atomic_intptr_t value;
} AtomicInt; */

/* struct AtomicInt
{
    atomic_intptr_t value;
}; */

void AtomicInt_free(AtomicInt *value);

typedef struct PlainCButOpaqueSwift PlainCButOpaqueSwift;

struct Plain;

AtomicInt *AtomicInt_init(intptr_t value);

intptr_t exchange(AtomicInt *atomic_value, intptr_t value);

void store(AtomicInt *atomic_value, intptr_t value);

intptr_t load(AtomicInt *atomic_value);

PlainCButOpaqueSwift PlainCButOpaqueSwift_init();

void take(struct PlainCButOpaqueSwift obj);