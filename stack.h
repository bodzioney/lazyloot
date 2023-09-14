#include <stdio.h>
#include <stdlib.h>
#include "values.h"

/**
 * Linked List with stack functionality
*/

void push(val_t);
void pop();
int isEmpty();  
val_t peek();

struct node{
    val_t val;
    struct node *next;
};

typedef struct node node;

node* head; 