#include <stdio.h>
#include <string.h>
#include <assert.h>

extern void my_printf (const char* format, ...);
int check_line (int n_test, char *buffer, int correct_line_length, int print_result);
void clean_buf (char *buf);

#define MAX_LINE_LENGTH 64

enum errors {
        NOT_PASSED = -1
};

#define TEST(print,frmt,...)    printf(frmt, ##__VA_ARGS__);                                            \
                                line_length = strlen(buffer);                                           \
                                my_printf(frmt, ##__VA_ARGS__);                                         \
                                check_line(n_test, buffer, line_length, print);                         \
                                buffer = original_buffer + (size_t) strlen(original_buffer);            \
                                n_test++;                                                               \

int main ()
{
        char original_buffer[MAX_LINE_LENGTH * 4] = {'\0'};
        setbuf(stdout, original_buffer);
        char *buffer = original_buffer;

        fprintf(stderr, "\n");

        int line_length = 0;
        char format_line[MAX_LINE_LENGTH] = {'\0'};
        int n_test = 1;

        TEST(1, "\nString to print\n")
        TEST(0, "Second string to print\n")
        TEST(1, "Check decimal: %d\n", 100)
        TEST(0, "%s %s\n", "line1", "line2")
        TEST(1, "%c %c %c\n", 'I', 'L', 'u')
        TEST(1, "%x %x %x\n", 16, 64, 256)

        fprintf(stderr, "\n");
        return 0;
}

int check_line (int n_test, char *buffer, int correct_line_length, int print_result)
{
        assert(buffer);

        for (int i = 0, j = correct_line_length; i < correct_line_length; i++, j++) {
                if (buffer[i] != buffer[j]) {
                        fprintf(stderr, "\nTest %d: NOT OK\n", n_test);
                        return NOT_PASSED;
                }
        }

        fprintf(stderr, "\nTest %d:      OK \n", n_test);
        if (print_result)
                fprintf(stderr, "\n==============================\n"
                                "%s\n==============================\n", buffer);
        return 0;
}

void clean_buf (char *buf)
{
        assert(buf);

        for (int i = 0; i < MAX_LINE_LENGTH * 4; i++)
                buf[i] = '\0';
}
