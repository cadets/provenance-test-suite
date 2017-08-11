#include<assert.h>
#include<unistd.h>
#include<errno.h>
#include<string.h>
#include<fcntl.h>
#include<stdlib.h>
#include<stdio.h>
#include<malloc_np.h>

#include<sys/uuid.h>
#include<uuid.h>
#include<sys/metaio.h>

char* make_temp_dir()
{
    char* dir = mkdtemp(strdup("/tmp/testXXXX"));
    if(!dir)
    {
        // dir creation failed
        fprintf(stderr, "failed to create directory\n");
        exit(1);
    }
    return dir;
}

int main()
{
    char** uuid_str = malloc(32*sizeof(char));
    char dirname[] = "/tmp/testXXXX";
    char origname[] = "./orig.bin";
    char newname[] = "./new.bin";
    char hlname[] = "./hl.bin";
    char slname[] = "./sl.bin";
    char* dir = make_temp_dir();
    char* content_buf = "Hello World!";
    printf("made dir: %s\n", dir);
    int dir_fd = open(dir,O_DIRECTORY|O_EXEC);
    if(dir_fd < 0)
    {
        printf("failed to open directory %s - error %s\n", dirname, strerror(errno));
        return 1;
    }
    // create file orig.bin
    int orig_fd = openat(dir_fd, origname, O_CREAT|O_RDWR, 0666);
    if(orig_fd < 0)
    {
        printf("failed to open file %s/%s - error %s\n", dirname, origname, strerror(errno));
        return 1;
    }
    write(orig_fd, content_buf, 5);
    // orig_uuid = getuuid(orig.bin)
    uuid_t *orig_uuid = malloc(sizeof(uuid_t));
    fgetuuid(orig_fd, orig_uuid);

    uint32_t status = 0;
    uuid_to_string(orig_uuid, uuid_str, &status);
    printf("Original UUID: %s\n", *uuid_str);

    // hard_link = hardlink(orig.bin)
    // hl_uuid = getuuid(hard_link)
    if(linkat(dir_fd, origname, dir_fd, hlname, 0))
    {
        printf("hard link creation failed - error %s\n", strerror(errno));
        return 1;
    }

    int hl_fd = openat(dir_fd, hlname, O_RDONLY);
    if (hl_fd < 0)
    {
        printf("failed to open file %s/%s - error %s\n", dirname, hlname, strerror(errno));
        return 1;
    }

    uuid_t *hl_uuid = malloc(sizeof(uuid_t));
    fgetuuid(hl_fd, hl_uuid);

    status = 0;
    uuid_to_string(hl_uuid, uuid_str, &status);
    assert(uuid_equal(orig_uuid, hl_uuid, &status));
    // soft_link = softlink(orig.bin)
    // sl_uuid = getuuid(soft_link)
    if(symlinkat(origname, dir_fd, slname))
    {
        printf("soft link creation failed - error %s\n", strerror(errno));
        return 1;
    }

    int sl_fd = openat(dir_fd, slname, O_RDONLY);
    if (sl_fd < 0)
    {
        printf("failed to open file %s/%s - error %s\n", dirname, slname, strerror(errno));
        return 1;
    }

    uuid_t *sl_uuid = malloc(sizeof(uuid_t));
    fgetuuid(sl_fd, sl_uuid);

    status = 0;
    uuid_to_string(sl_uuid, uuid_str, &status);
    assert(uuid_equal(orig_uuid, sl_uuid, &status));
    // moved_file = move(orig.bin, new_location)
    // moved_uuid = getuuid(moved_file)
    if(renameat(dir_fd, origname, dir_fd, newname))
    {
        printf("failed to rename file %s/%s to %s/%s - error %s\n", dirname, origname, dirname, newname, strerror(errno));
        return 1;
    }
    int new_fd = openat(dir_fd, newname, O_RDONLY);
    if (new_fd < 0)
    {
        printf("failed to open file %s/%s - error %s\n", dirname, newname, strerror(errno));
        return 1;
    }
    uuid_t *new_uuid = malloc(sizeof(uuid_t));
    fgetuuid(new_fd, new_uuid);

    status = 0;
    uuid_to_string(sl_uuid, uuid_str, &status);
    assert(uuid_equal(new_uuid, orig_uuid, &status));
    // dup_file = new_file(original path)
    // dup_uuid = getuuid(dup_file)
    int dup_fd = openat(dir_fd, origname, O_CREAT|O_RDWR, 0666);
    uuid_t *dup_uuid = malloc(sizeof(uuid_t));
    fgetuuid(dup_fd, dup_uuid);

    status = 0;
    uuid_to_string(dup_uuid, uuid_str, &status);
    printf("New UUID: %s\n", *uuid_str);

    assert(!uuid_equal(dup_uuid, orig_uuid, &status));
    assert(!uuid_equal(dup_uuid, hl_uuid, &status));

    int sl_fd_2 = openat(dir_fd, slname, O_RDONLY);
    if (sl_fd_2 < 0)
    {
        printf("failed to open file %s/%s - error %s\n", dirname, slname, strerror(errno));
        return 1;
    }

    uuid_t *sl_uuid_2 = malloc(sizeof(uuid_t));
    fgetuuid(sl_fd_2, sl_uuid_2);

    status = 0;
    uuid_to_string(sl_uuid_2, uuid_str, &status);
    assert(uuid_equal(dup_uuid, sl_uuid_2, &status));

    close(orig_fd);
    close(hl_fd);
    close(sl_fd);
    close(new_fd);
    close(dup_fd);
    close(sl_fd_2);
    unlinkat(dir_fd, origname, 0);
    unlinkat(dir_fd, slname, 0);
    unlinkat(dir_fd, hlname, 0);
    unlinkat(dir_fd, newname, 0);
    close(dir_fd);
    rmdir(dir);
    return 0;
}
