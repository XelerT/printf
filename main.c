extern void my_printf (const char* format, ...);

int main ()
{
        my_printf("%d %s %d %d %d %d %d \n", 1, "It's working!", 3, 4, 5, 6, 7);
        return 0;
}


// ./test > out diff out reference -- error
