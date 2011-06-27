#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/timeb.h>


bool emit_timestamp = true;

void usage()
{
  fprintf(stderr, "Usage:\n");
  fprintf(stderr, "dump-serial serial-device-name baud-rate\n");
  exit(1);
}

void show_progress()
{
  static int progress=0;
  char *progress_str = "|/-\\";
  progress = (progress + 1) % strlen(progress_str);
  fprintf(stderr, "%c%c", progress_str[progress], 8);
}

int main(int argc, char **argv)
{
  timeb tb;  
  /*
  ftime(&tb);
  printf("%ld.%d,",(long)tb.time,(int)tb.millitm);
  return 1;
  */
  
  if (argc != 3) usage();
  char *filename = argv[1];
  int baudrate = atoi(argv[2]);
  if (!baudrate) usage();
  


  while (1) {
    fprintf(stderr, "Capturing %s at %d baud\n", filename, baudrate);
    int fd = open(filename, O_RDONLY | O_NONBLOCK);
    FILE *in= fdopen(fd, "r");
    if (!in) {
      fprintf(stderr, "Can't open %s for reading\n", filename);
      usage();
    }
    
    char buf[200];
    sprintf(buf, "stty -f %s %d -crtscts", filename, baudrate);
    system(buf);
    
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | ~O_NONBLOCK);
    
    time_t t;
    time(&t);
    fprintf(stderr, "Capture starting at %s\n", ctime(&t));
    
  
    bool beginning_of_line = true;
    
    while (1) {
      int c = getc(in);
      if (c == EOF) break; // happens when there's an error reading, e.g. USB cable is unplugged
      if (beginning_of_line) {
      	ftime(&tb);
      	printf("%ld.%d,",(long)tb.time,(int)tb.millitm);
      }
      putchar(c);
      fflush(stdout);
      beginning_of_line = (c == '\n');
      if (beginning_of_line) show_progress();
    }
    
    time(&t);
    fprintf(stderr, "Capture ending at %s\n", ctime(&t));
    fclose(in);
  }
}
