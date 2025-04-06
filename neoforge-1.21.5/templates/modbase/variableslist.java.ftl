<#-- @formatter:off -->
<#include "variablesutils.ftl">

package ${package}.network;

import ${package}.${JavaModName};

import net.neoforged.neoforge.event.level.LevelEvent;
import com.mojang.datafixers.util.Pair;
import net.minecraft.nbt.Tag;
import net.minecraft.world.item.ItemStack;
import net.minecraft.core.Direction;
import net.minecraft.world.level.block.state.BlockState;
import com.mojang.serialization.Codec;

@EventBusSubscriber(bus = EventBusSubscriber.Bus.MOD) public class ${JavaModName}Variables {

   <#if w.hasVariablesOfScope("GLOBAL_WORLD") || w.hasVariablesOfScope("GLOBAL_MAP")>
    public static void registerEventHandlers() {
        NeoForge.EVENT_BUS.addListener(GameEventHandler::onWorldCreate);
        NeoForge.EVENT_BUS.addListener(GameEventHandler::onWorldLoad);
    }
    </#if>

    public static final DeferredRegister<AttachmentType<?>> ATTACHMENT_TYPES = DeferredRegister.create(NeoForgeRegistries.Keys.ATTACHMENT_TYPES, ${JavaModName}.MODID);

    <#if w.hasVariablesOfScope("PLAYER_LIFETIME") || w.hasVariablesOfScope("PLAYER_PERSISTENT")>
    public static final Supplier<AttachmentType<PlayerVariables>> PLAYER_VARIABLES = ATTACHMENT_TYPES.register("player_variables", () -> AttachmentType.serializable(() -> new PlayerVariables()).build());
    </#if>

    <#if w.hasVariablesOfScope("GLOBAL_SESSION")>
        <#list variables as var>
            <#if var.getScope().name() == "GLOBAL_SESSION">
                <@var.getType().getScopeDefinition(generator.getWorkspace(), "GLOBAL_SESSION")['init']?interpret/>
            </#if>
        </#list>
    </#if>

    @SubscribeEvent public static void init(FMLCommonSetupEvent event) {
        <#if w.hasVariablesOfScope("GLOBAL_WORLD") || w.hasVariablesOfScope("GLOBAL_MAP")>
            ${JavaModName}.addNetworkMessage(SavedDataSyncMessage.TYPE, SavedDataSyncMessage.STREAM_CODEC, SavedDataSyncMessage::handleData);
        </#if>

        <#if w.hasVariablesOfScope("PLAYER_LIFETIME") || w.hasVariablesOfScope("PLAYER_PERSISTENT")>
            ${JavaModName}.addNetworkMessage(PlayerVariablesSyncMessage.TYPE, PlayerVariablesSyncMessage.STREAM_CODEC, PlayerVariablesSyncMessage::handleData);
        </#if>
    }

    <#if w.hasVariablesOfScope("PLAYER_LIFETIME") || w.hasVariablesOfScope("PLAYER_PERSISTENT") || w.hasVariablesOfScope("GLOBAL_WORLD") || w.hasVariablesOfScope("GLOBAL_MAP")>
    @EventBusSubscriber public static class EventBusVariableHandlers {

        <#if w.hasVariablesOfScope("PLAYER_LIFETIME") || w.hasVariablesOfScope("PLAYER_PERSISTENT")>
        @SubscribeEvent public static void onPlayerLoggedInSyncPlayerVariables(PlayerEvent.PlayerLoggedInEvent event) {
            if (event.getEntity() instanceof ServerPlayer player)
                player.getData(PLAYER_VARIABLES).syncPlayerVariables(event.getEntity());
        }

        @SubscribeEvent public static void onPlayerRespawnedSyncPlayerVariables(PlayerEvent.PlayerRespawnEvent event) {
            if (event.getEntity() instanceof ServerPlayer player)
                player.getData(PLAYER_VARIABLES).syncPlayerVariables(event.getEntity());
        }

        @SubscribeEvent public static void onPlayerChangedDimensionSyncPlayerVariables(PlayerEvent.PlayerChangedDimensionEvent event) {
            if (event.getEntity() instanceof ServerPlayer player)
                player.getData(PLAYER_VARIABLES).syncPlayerVariables(event.getEntity());
        }

        @SubscribeEvent public static void clonePlayer(PlayerEvent.Clone event) {
            PlayerVariables original = event.getOriginal().getData(PLAYER_VARIABLES);
            PlayerVariables clone = new PlayerVariables();
            <#list variables as var>
                <#if var.getScope().name() == "PLAYER_PERSISTENT">
                clone.${var.getName()} = original.${var.getName()};
                </#if>
            </#list>
            if(!event.isWasDeath()) {
                <#list variables as var>
                    <#if var.getScope().name() == "PLAYER_LIFETIME">
                    clone.${var.getName()} = original.${var.getName()};
                    </#if>
                </#list>
            }
            event.getEntity().setData(PLAYER_VARIABLES, clone);
        }
        </#if>

        <#if w.hasVariablesOfScope("GLOBAL_WORLD") || w.hasVariablesOfScope("GLOBAL_MAP")>
        @SubscribeEvent public static void onPlayerLoggedIn(PlayerEvent.PlayerLoggedInEvent event) {
            if (event.getEntity() instanceof ServerPlayer player) {
                SavedData mapdata = MapVariables.get(event.getEntity().level());
                SavedData worlddata = WorldVariables.get(event.getEntity().level());
                if(mapdata != null)
                    PacketDistributor.sendToPlayer(player, new SavedDataSyncMessage(0, mapdata));
                if(worlddata != null)
                    PacketDistributor.sendToPlayer(player, new SavedDataSyncMessage(1, worlddata));
            }
        }

        @SubscribeEvent public static void onPlayerChangedDimension(PlayerEvent.PlayerChangedDimensionEvent event) {
            if (event.getEntity() instanceof ServerPlayer player) {
                SavedData worlddata = WorldVariables.get(event.getEntity().level());
                if(worlddata != null)
                    PacketDistributor.sendToPlayer(player, new SavedDataSyncMessage(1, worlddata));
            }
        }
        </#if>
    }
    </#if>

    <#if w.hasVariablesOfScope("GLOBAL_WORLD") || w.hasVariablesOfScope("GLOBAL_MAP")>

public static class GameEventHandler {
    @SubscribeEvent
    public static void onWorldCreate(LevelEvent.CreateSpawnPosition event) {
        if (!event.getLevel().isClientSide() && event.getLevel() instanceof ServerLevel level) {
            // Инициализация WorldVariables только при создании мира
            WorldVariables worldVariables = WorldVariables.get(level);
            <#list variables as var>
                <#if var.getScope().name() == "GLOBAL_WORLD">
                    <#if var.getType().getName() == "string">
            worldVariables.${var.getName()} = "${var.value!var.getType().getDefaultValue(generator.getWorkspace())}";
                    <#elseif var.getType().getName() == "logic">
            worldVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())?string("true", "false")};
                    <#elseif var.getType().getName() == "number">
            worldVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())};
                    <#else>
            if (worldVariables.${var.getName()} == null) {
                worldVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())};
            }
                    </#if>
                </#if>
            </#list>
            worldVariables.setDirty();

            // Инициализация MapVariables только при создании мира
            MapVariables mapVariables = MapVariables.get(level);
            <#list variables as var>
                <#if var.getScope().name() == "GLOBAL_MAP">
                    <#if var.getType().getName() == "string">
            mapVariables.${var.getName()} = "${var.value!var.getType().getDefaultValue(generator.getWorkspace())}";
                    <#elseif var.getType().getName() == "logic">
            mapVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())?string("true", "false")};
                    <#elseif var.getType().getName() == "number">
            mapVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())};
                    <#else>
            if (mapVariables.${var.getName()} == null) {
                mapVariables.${var.getName()} = ${var.value!var.getType().getDefaultValue(generator.getWorkspace())};
            }
                    </#if>
                </#if>
            </#list>
            mapVariables.setDirty();
        }
    }

    @SubscribeEvent
    public static void onWorldLoad(LevelEvent.Load event) {
        // Только синхронизация при загрузке существующего мира
        if (!event.getLevel().isClientSide() && event.getLevel() instanceof ServerLevel level) {
            WorldVariables.get(level).setDirty();
            MapVariables.get(level).setDirty();
        }
    }
}

    public static class WorldVariables extends SavedData {
        public static final String DATA_NAME = "${modid}_worldvars";

        <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
        public String empty_string = "";
        <#else>
            <#list variables as var>
                <#if var.getScope().name() == "GLOBAL_WORLD">
                    public ${getJavaType(var.getType()!)?default("String")} ${var.getName()};
                </#if>
            </#list>
        </#if>

        public static final Codec<WorldVariables> CODEC = new Codec<WorldVariables>() {
            @Override
            public <T> DataResult<Pair<WorldVariables, T>> decode(DynamicOps<T> ops, T input) {
                return ops.getMap(input).flatMap(map -> {
                    Builder builder = new Builder();

                    <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                    DataResult<String> emptyStringResult = ops.getStringValue(map.get("empty_string"));
                    if (emptyStringResult.result().isEmpty()) {
                        return DataResult.error(() -> "Missing or invalid 'empty_string' field");
                    }
                    builder.empty_string = emptyStringResult.result().get();
                    <#else>
                        <#assign first = true>
                        <#list variables as var>
                            <#if var.getScope().name() == "GLOBAL_WORLD">
                    ${getCodecType(var.getType())}.decode(ops, map.get("${var.getName()}"))
                        .result().ifPresent(v -> builder.${var.getName()} = v.getFirst());
                                <#assign first = false>
                            </#if>
                        </#list>
                    </#if>

                    return DataResult.success(Pair.of(builder.build(), ops.empty()));
                });
            }

            @Override
            public <T> DataResult<T> encode(WorldVariables input, DynamicOps<T> ops, T prefix) {
                RecordBuilder<T> recordBuilder = ops.mapBuilder();

                <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                recordBuilder.add("empty_string", ops.createString(input.empty_string));
                <#else>
                    <#assign first = true>
                    <#list variables as var>
                        <#if var.getScope().name() == "GLOBAL_WORLD">
                recordBuilder.add("${var.getName()}", ${getCodecType(var.getType())}.encode(input.${var.getName()}, ops, ops.empty()));
                            <#assign first = false>
                        </#if>
                    </#list>
                </#if>

                return recordBuilder.build(prefix);
            }
        };

        private static class Builder {
            <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
            String empty_string = "";
            <#else>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_WORLD">
           ${getJavaType(var.getType()!)} ${var.getName()} = <#if var.getType().getJavaType(generator.getWorkspace()) == "String">"${var.value!var.getType().getDefaultValue(generator.getWorkspace())}"<#else>${var.value!var.getType().getDefaultValue(generator.getWorkspace())}</#if>;
                    </#if>
                </#list>
            </#if>

            WorldVariables build() {
                return new WorldVariables(
                    <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                    empty_string
                    <#else>
                        <#assign first = true>
                        <#list variables as var>
                            <#if var.getScope().name() == "GLOBAL_WORLD">
                                <#if !first>, </#if>${var.getName()}
                                <#assign first = false>
                            </#if>
                        </#list>
                    </#if>
                );
            }
        }

        public static final SavedDataType<WorldVariables> TYPE = new SavedDataType<>(
            DATA_NAME,
            ctx -> new WorldVariables(
                <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                    ""
                <#else>
                    <#assign first = true>
                    <#list variables as var>
                        <#if var.getScope().name() == "GLOBAL_WORLD">
                            <#if !first>, </#if>${getDefaultValue(var.getType()!)?default("\"\"")}
                            <#assign first = false>
                        </#if>
                    </#list>
                </#if>
            ),
            ctx -> CODEC,
            DataFixTypes.LEVEL
        );

        public WorldVariables(
            <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                String empty_string
            <#else>
                <#assign first = true>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_WORLD">
                        <#if !first>, </#if>${getJavaType(var.getType()!)?default("String")} ${var.getName()}
                        <#assign first = false>
                    </#if>
                </#list>
            </#if>
        ) {
            <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                this.empty_string = empty_string;
            <#else>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_WORLD">
                this.${var.getName()} = ${var.getName()};
                    </#if>
                </#list>
            </#if>
        }

        public void syncData(LevelAccessor world) {
            this.setDirty();
            if (world instanceof ServerLevel level) {
                PacketDistributor.sendToPlayersInDimension(level, new SavedDataSyncMessage(1, this));
            }
        }

        static WorldVariables clientSide = new WorldVariables(
            <#if !w.hasVariablesOfScope("GLOBAL_WORLD")>
                ""
            <#else>
                <#assign first = true>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_WORLD">
                        <#if !first>, </#if><#if var.getType().getJavaType(generator.getWorkspace()) == "String">"${var.value!var.getType().getDefaultValue(generator.getWorkspace())}"<#else>${var.value!var.getType().getDefaultValue(generator.getWorkspace())}</#if>
                        <#assign first = false>
                    </#if>
                </#list>
            </#if>
        );

        public static WorldVariables get(LevelAccessor world) {
            if (world instanceof ServerLevel level) {
                return level.getDataStorage().computeIfAbsent(TYPE);
            } else {
                return clientSide;
            }
        }
    }

   public static class MapVariables extends SavedData {
        public static final String DATA_NAME = "${modid}_mapvars";

        <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
        public String empty_string = "";
        <#else>
            <#list variables as var>
                <#if var.getScope().name() == "GLOBAL_MAP">
                    public ${getJavaType(var.getType()!)?default("String")} ${var.getName()};
                </#if>
            </#list>
        </#if>

        public static final Codec<MapVariables> CODEC = new Codec<MapVariables>() {
            @Override
            public <T> DataResult<Pair<MapVariables, T>> decode(DynamicOps<T> ops, T input) {
                return ops.getMap(input).flatMap(map -> {
                    Builder builder = new Builder();

                    <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                    DataResult<String> emptyStringResult = ops.getStringValue(map.get("empty_string"));
                    if (emptyStringResult.result().isEmpty()) {
                        return DataResult.error(() -> "Missing or invalid 'empty_string' field");
                    }
                    builder.empty_string = emptyStringResult.result().get();
                    <#else>
                        <#assign first = true>
                        <#list variables as var>
                            <#if var.getScope().name() == "GLOBAL_MAP">
                    ${getCodecType(var.getType())}.decode(ops, map.get("${var.getName()}"))
                        .result().ifPresent(v -> builder.${var.getName()} = v.getFirst());
                                <#assign first = false>
                            </#if>
                        </#list>
                    </#if>

                    return DataResult.success(Pair.of(builder.build(), ops.empty()));
                });
            }

            @Override
            public <T> DataResult<T> encode(MapVariables input, DynamicOps<T> ops, T prefix) {
                RecordBuilder<T> recordBuilder = ops.mapBuilder();

                <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                recordBuilder.add("empty_string", ops.createString(input.empty_string));
                <#else>
                    <#assign first = true>
                    <#list variables as var>
                        <#if var.getScope().name() == "GLOBAL_MAP">
                recordBuilder.add("${var.getName()}", ${getCodecType(var.getType())}.encode(input.${var.getName()}, ops, ops.empty()));
                            <#assign first = false>
                        </#if>
                    </#list>
                </#if>

                return recordBuilder.build(prefix);
            }
        };

        private static class Builder {
            <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
            String empty_string = "";
            <#else>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_MAP">
            ${getJavaType(var.getType()!)} ${var.getName()} = <#if var.getType().getJavaType(generator.getWorkspace()) == "String">"${var.value!var.getType().getDefaultValue(generator.getWorkspace())}"<#else>${var.value!var.getType().getDefaultValue(generator.getWorkspace())}</#if>;
                    </#if>
                </#list>
            </#if>

            MapVariables build() {
                return new MapVariables(
                    <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                    empty_string
                    <#else>
                        <#assign first = true>
                        <#list variables as var>
                            <#if var.getScope().name() == "GLOBAL_MAP">
                                <#if !first>, </#if>${var.getName()}
                                <#assign first = false>
                            </#if>
                        </#list>
                    </#if>
                );
            }
        }

        public static final SavedDataType<MapVariables> TYPE = new SavedDataType<>(
            DATA_NAME,
            ctx -> new MapVariables(
                <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                    ""
                <#else>
                    <#assign first = true>
                    <#list variables as var>
                        <#if var.getScope().name() == "GLOBAL_MAP">
                            <#if !first>, </#if>${getDefaultValue(var.getType()!)?default("\"\"")}
                            <#assign first = false>
                        </#if>
                    </#list>
                </#if>
            ),
            ctx -> CODEC,
            DataFixTypes.LEVEL
        );

        public MapVariables(
            <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                String empty_string
            <#else>
                <#assign first = true>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_MAP">
                        <#if !first>, </#if>${getJavaType(var.getType()!)?default("String")} ${var.getName()}
                        <#assign first = false>
                    </#if>
                </#list>
            </#if>
        ) {
            <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                this.empty_string = empty_string;
            <#else>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_MAP">
                this.${var.getName()} = ${var.getName()};
                    </#if>
                </#list>
            </#if>
        }

        public void syncData(LevelAccessor world) {
            this.setDirty();
            if (world instanceof Level && !world.isClientSide()) {
                PacketDistributor.sendToAllPlayers(new SavedDataSyncMessage(0, this));
            }
        }

        static MapVariables clientSide = new MapVariables(
            <#if !w.hasVariablesOfScope("GLOBAL_MAP")>
                ""
            <#else>
                <#assign first = true>
                <#list variables as var>
                    <#if var.getScope().name() == "GLOBAL_MAP">
                        <#if !first>, </#if><#if var.getType().getJavaType(generator.getWorkspace()) == "String">"${var.value!var.getType().getDefaultValue(generator.getWorkspace())}"<#else>${var.value!var.getType().getDefaultValue(generator.getWorkspace())}</#if>
                        <#assign first = false>
                    </#if>
                </#list>
            </#if>
        );

        public static MapVariables get(LevelAccessor world) {
            if (world instanceof ServerLevelAccessor serverLevelAcc) {
                return serverLevelAcc.getLevel().getServer().getLevel(Level.OVERWORLD).getDataStorage()
                    .computeIfAbsent(TYPE);
            } else {
                return clientSide;
            }
        }
    }

    public record SavedDataSyncMessage(int dataType, SavedData data) implements CustomPacketPayload {
        public static final Type<SavedDataSyncMessage> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath(${JavaModName}.MODID, "saved_data_sync"));

        public static final StreamCodec<RegistryFriendlyByteBuf, SavedDataSyncMessage> STREAM_CODEC = StreamCodec.of(
            (buffer, message) -> {
                buffer.writeInt(message.dataType);
                if (message.data != null) {
                    CompoundTag tag = switch (message.dataType) {
                        case 0 -> (CompoundTag) MapVariables.CODEC.encodeStart(NbtOps.INSTANCE, (MapVariables) message.data)
                                  .getOrThrow();
                        case 1 -> (CompoundTag) WorldVariables.CODEC.encodeStart(NbtOps.INSTANCE, (WorldVariables) message.data)
                                  .getOrThrow();
                        default -> throw new IllegalArgumentException("Unknown data type");
                    };
                    buffer.writeNbt(tag);
                }
            },
            buffer -> {
                int dataType = buffer.readInt();
                CompoundTag nbt = buffer.readNbt();
                SavedData data = switch (dataType) {
                    case 0 -> MapVariables.CODEC.parse(NbtOps.INSTANCE, nbt).getOrThrow();
                    case 1 -> WorldVariables.CODEC.parse(NbtOps.INSTANCE, nbt).getOrThrow();
                    default -> null;
                };
                return new SavedDataSyncMessage(dataType, data);
            }
        );

        @Override
        public Type<SavedDataSyncMessage> type() {
            return TYPE;
        }

        public static void handleData(final SavedDataSyncMessage message, final IPayloadContext context) {
            if (context.flow() == PacketFlow.CLIENTBOUND && message.data != null) {
                context.enqueueWork(() -> {
                    if (message.dataType == 0) {
                        MapVariables.clientSide = (MapVariables) message.data;
                    } else {
                        WorldVariables.clientSide = (WorldVariables) message.data;
                    }
                }).exceptionally(e -> {
                    context.connection().disconnect(Component.literal(e.getMessage()));
                    return null;
                });
            }
        }
    }
    </#if>

    <#if w.hasVariablesOfScope("PLAYER_LIFETIME") || w.hasVariablesOfScope("PLAYER_PERSISTENT")>
    public static class PlayerVariables implements INBTSerializable<CompoundTag> {

        <#list variables as var>
            <#if var.getScope().name() == "PLAYER_LIFETIME">
                <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_LIFETIME")['init']?interpret/>
            <#elseif var.getScope().name() == "PLAYER_PERSISTENT">
                <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_PERSISTENT")['init']?interpret/>
            </#if>
        </#list>

        private void putItemStack(CompoundTag nbt, String key, ItemStack stack, HolderLookup.Provider lookupProvider) {
            if (!stack.isEmpty()) {
                nbt.put(key, stack.save(lookupProvider));
            } else {
                nbt.putBoolean(key + "_empty", true);
            }
        }

        private ItemStack getItemStack(CompoundTag nbt, String key, HolderLookup.Provider lookupProvider) {
            if (nbt.contains(key + "_empty")) {
                return ItemStack.EMPTY;
            }
            return nbt.contains(key)
                ? ItemStack.parse(lookupProvider, nbt.getCompoundOrEmpty(key)).orElse(ItemStack.EMPTY)
                : ItemStack.EMPTY;
        }

        @Override public CompoundTag serializeNBT(HolderLookup.Provider lookupProvider) {
            CompoundTag nbt = new CompoundTag();
            <#list variables as var>
                <#if var.getScope().name() == "PLAYER_LIFETIME">
                    <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_LIFETIME")['write']?interpret/>
                <#elseif var.getScope().name() == "PLAYER_PERSISTENT">
                    <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_PERSISTENT")['write']?interpret/>
                </#if>
            </#list>
            return nbt;
        }

        @Override public void deserializeNBT(HolderLookup.Provider lookupProvider, CompoundTag nbt) {
            <#list variables as var>
                <#if var.getScope().name() == "PLAYER_LIFETIME">
                    <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_LIFETIME")['read']?interpret/>
                <#elseif var.getScope().name() == "PLAYER_PERSISTENT">
                    <@var.getType().getScopeDefinition(generator.getWorkspace(), "PLAYER_PERSISTENT")['read']?interpret/>
                </#if>
            </#list>
        }

        public void syncPlayerVariables(Entity entity) {
            if (entity instanceof ServerPlayer serverPlayer)
                PacketDistributor.sendToPlayer(serverPlayer, new PlayerVariablesSyncMessage(this));
        }

    }

    public record PlayerVariablesSyncMessage(PlayerVariables data) implements CustomPacketPayload {

        public static final Type<PlayerVariablesSyncMessage> TYPE = new Type<>(ResourceLocation.fromNamespaceAndPath(${JavaModName}.MODID, "player_variables_sync"));

        public static final StreamCodec<RegistryFriendlyByteBuf, PlayerVariablesSyncMessage> STREAM_CODEC = StreamCodec.of(
                (RegistryFriendlyByteBuf buffer, PlayerVariablesSyncMessage message) ->
                        buffer.writeNbt(message.data().serializeNBT(buffer.registryAccess())),
                (RegistryFriendlyByteBuf buffer) -> {
                    PlayerVariablesSyncMessage message = new PlayerVariablesSyncMessage(new PlayerVariables());
                    message.data.deserializeNBT(buffer.registryAccess(), buffer.readNbt());
                    return message;
                }
        );

        @Override public Type<PlayerVariablesSyncMessage> type() {
            return TYPE;
        }

        public static void handleData(final PlayerVariablesSyncMessage message, final IPayloadContext context) {
            if (context.flow() == PacketFlow.CLIENTBOUND && message.data != null) {
                context.enqueueWork(() ->
                    context.player().getData(PLAYER_VARIABLES).deserializeNBT(context.player().registryAccess(), message.data.serializeNBT(context.player().registryAccess()))
                ).exceptionally(e -> {
                    context.connection().disconnect(Component.literal(e.getMessage()));
                    return null;
                });
            }
        }

    }
    </#if>

}
<#-- @formatter:on -->