#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define DATA "I'm a little socket, short and stout."
#define NAME "im_a_socket"

void parent(int sock)
{
    int length;
    struct sockaddr name;
    char buf[1024];

    name.sa_family = AF_UNIX;
    strcpy(name.sa_data, NAME);
    if (bind(sock, &name, sizeof(struct sockaddr))) {
        perror("binding name to datagram socket");
        exit(1);
    }
    // Recieve from socket
    if (recv(sock, buf, 1024, 0) < 0)
        perror("receiving datagram packet");
    close(sock);
    unlink(NAME);
}

void child(int sock)
{
    struct sockaddr name;

    name.sa_family = AF_UNIX;
    strcpy(name.sa_data, NAME);
    // Send string over socket
    if (sendto(sock, DATA, sizeof(DATA), 0,
                &name, sizeof(struct sockaddr)) < 0) {
        perror("sending datagram message");
    }
    close(sock);
}

int main(void)
{
    // Create socket
    int sock = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("opening datagram socket");
        exit(1);
    }
    if (!fork()) {
        child(sock);
    } else {
        parent(sock);
    }

    return 0;
}
