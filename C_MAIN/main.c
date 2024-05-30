#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "hbird_sdk_soc.h"
#include "dma.h"
#include "tanh_lut.h"
#include "conv_golden_pattern.h"

int main(void)
{   

    printf("\r\n###########Begin Test!!!###########\r\n");
    
    
    PLIC_Register_IRQ(PLIC_DMA_IRQn, 1, dma_irq_base_handler);  
    __enable_irq();

    dma_init(DMA_CFG);

    uint32_t a[2140] = {0};
    uint32_t b[9] = {0};
    uint32_t c[480] = {0};
    uint32_t d[120] = {0};
    
    for (int i = 0; i < 2140; i++){
        a[i] = tanh_lut_combined[i];
    }

    for (int i = 0; i < 9; i++)
    {
        uint16_t weight_1 = weight[0][i];
        uint16_t weight_2 = weight[0][i+9];
        b[i] = ((uint32_t)weight_2 << 16) | weight_1;
    }

    for (int i = 0; i < 30; i++)
    {
        for (int j = 0; j < 16; j++)
        {
            uint16_t ifmap_1 = ifmap[i][j];
            uint16_t ifmap_2 = ifmap[i][j+16];
            c[j + i * 16] = ((uint32_t)ifmap_2 << 16) | ifmap_1;
        }
    }

    // printf("\r\nAddress of tanh_lut_combined is %#x\r\n", &tanh_lut_combined[5]);

    uint32_t ramsel = 2;
    // adder_ramsel(ADD_CFG,2);
    

    dma_config(DMA_CFG, &ramsel, 0x10042004, 1);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);
    
    // printf("\r\nramsel is %d\r\n", ramsel);

    dma_config(DMA_CFG, a, 0x10042008, 2140);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);

    ramsel = 1;
    // adder_ramsel(ADD_CFG,2);
    
    
    dma_config(DMA_CFG, &ramsel, 0x10042004, 1);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);

    

    dma_config(DMA_CFG, b, 0x10042ff7, 9);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);

    

    dma_config(DMA_CFG, c, 0x10042009, 480);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);

    uint32_t start[2] = {1, 0};

    dma_config(DMA_CFG, &start, 0x10042000, 2);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);


    dma_config(DMA_CFG, 0x10042009, d, 120);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);


    for (int i = 0; i < 120; i++)
    {   
        printf("d[%d] is %x\n", i, d[i]);
    }

    // 2 round

    for (int i = 8; i >= 0; i--)
    {
        uint16_t weight_1 = weight[0][i];
        uint16_t weight_2 = weight[0][i+9];
        b[8-i] = ((uint32_t)weight_2 << 16) | weight_1;
    }

    dma_config(DMA_CFG, b, 0x10042ff7, 9);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);

    dma_config(DMA_CFG, &start, 0x10042000, 2);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);


    dma_config(DMA_CFG, 0x10042081, d, 120);
    dma_start(DMA_CFG);
    dma_wait(DMA_CFG);


    for (int i = 0; i < 120; i++)
    {   
        printf("d[%d] is %x\n", i, d[i]);
    }

    // dma_disbale(DMA_CFG);

    printf("\r\n###########Finish!!!###########\r\n");

    return 0;

}
