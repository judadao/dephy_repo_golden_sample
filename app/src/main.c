#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(golden_sample, LOG_LEVEL_INF);

int main(void)
{
    LOG_INF("Dephy product golden sample starting");
    LOG_INF("Dephy product golden sample ready");
    return 0;
}
