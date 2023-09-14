#include "stack.h"
#include "values.h"
#include <stdio.h>
#include <stdlib.h>

struct node *head = NULL;

void push(val_t val)
{
    node* tmp = malloc(sizeof(node));
    tmp->val = val;

    tmp->next = head;

    head = tmp;
}

void pop()
{
    node* tmp;
    tmp = head;
    head = head->next;
    free(tmp);
}

val_t peek()
{
    if (!isEmpty()) {
        return head->val;
    }
    else {
        exit(EXIT_FAILURE);
    }
}

int isEmpty()
{
    return head == NULL;
}