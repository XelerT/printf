### My simple printf
        Copy of the standart printf.
## Supported formats
        - %s
        - %d
        - %b
        - %o
        - %x
        - %c
        - %%

## Example
---
> Need to add extern function that must be linked from object file.

```C
extern void my_printf (const char* format, ...);

int main ()
{
        my_printf("%d %s %d %d %d %d %d \n", 1, "It's working!", 3, 4, 5, 6, 7);
        return 0;
}
```
