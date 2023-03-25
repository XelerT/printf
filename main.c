extern void my_printf (const char* format, ...);

int main ()
{
        my_printf("%d %s %% \n", 100, "IT's working", "12");
        return 0;
}


// ./test > out diff out reference -- error
