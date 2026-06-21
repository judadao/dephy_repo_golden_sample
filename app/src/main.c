#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

#include <dephy_iot/iot.h>

LOG_MODULE_REGISTER(golden_sample, LOG_LEVEL_INF);

int main(void)
{
    dephy_iot_config_t cfg = {
        .device_id = "golden-sample",
    };

    LOG_INF("Dephy product golden sample starting");
    if (dephy_iot_init(&cfg) != 0) {
        LOG_ERR("dephy_iot_init failed");
        return 1;
    }

    LOG_INF("Dephy product golden sample ready");
    return 0;
}

