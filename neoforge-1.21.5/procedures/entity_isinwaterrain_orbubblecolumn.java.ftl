(${input$entity}.isInFluidType(Fluids.WATER.getFluidType())
				|| ${input$entity}.level().isRainingAt(entity.blockPosition())
				|| ${input$entity}.level().getBlockState(entity.blockPosition()).getBlock() instanceof BubbleColumnBlock)