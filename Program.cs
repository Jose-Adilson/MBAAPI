using System.Text.Json.Serialization;
using Amazon.Lambda.Serialization.SystemTextJson;

var builder = WebApplication.CreateBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, LambdaApiJsonSerializerContext.Default);
});

builder.Services.AddAWSLambdaHosting(
    LambdaEventSource.HttpApi,
    options =>
    {
        options.Serializer = new SourceGeneratorLambdaJsonSerializer<LambdaApiJsonSerializerContext>();
    }
);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapGet("/health", () => new HealthResponse("healthy", DateTime.UtcNow))
    .WithName("Health");

app.MapGet("/ping", () => new PingResponse("pong"))
    .WithName("Ping");

var benchmark = app.MapGroup("/api/benchmark");

benchmark.MapGet("/minimal", () => new MinimalResponse("minimal response"));

benchmark.MapGet("/small", () => new SmallResponse(
    1, "Test Item", "This is a small fixed payload for benchmarking", DateTime.UtcNow, 42));

benchmark.MapGet("/medium", () =>
{
    var items = Enumerable.Range(1, 10).Select(i => new MediumItem(
        i, $"Item {i}", "This is a medium fixed payload for benchmarking purposes",
        DateTime.UtcNow, i * 100, i % 2 == 0)).ToList();
    return new MediumResponse(items, items.Count);
});

benchmark.MapGet("/large", () =>
{
    var items = Enumerable.Range(1, 100).Select(i => new LargeItem(
        i, $"Item {i}", "This is a large fixed payload for benchmarking purposes with additional content",
        DateTime.UtcNow, i * 100, i % 2 == 0,
        i % 3 == 0 ? "A" : i % 3 == 1 ? "B" : "C")).ToList();
    return new LargeResponse(items, items.Count, items.Count * 256);
});

benchmark.MapPost("/echo", (EchoRequest request) => new EchoResponse(request, DateTime.UtcNow));

benchmark.MapGet("/compute", () =>
{
    int result = 0;
    for (int i = 0; i < 10000; i++)
    {
        result += i * i;
    }
    return new ComputeResponse(result, DateTime.UtcNow);
});

benchmark.MapGet("/memory", () =>
{
    // 10 Megabytes
    var data = new byte[10 * 1024 * 1024];

    data[0] = 1;
    data[^1] = 2;

    return new MemoryResponse(data.Length, data[0] + data[^1], DateTime.UtcNow);
});

app.Run();


public record HealthResponse(string status, DateTime timestamp);
public record MinimalResponse(string message);
public record SmallResponse(int id, string name, string description, DateTime timestamp, int value);
public record MediumItem(int id, string name, string description, DateTime timestamp, int value, bool active);
public record MediumResponse(List<MediumItem> items, int count);
public record LargeItem(int id, string name, string description, DateTime timestamp, int value, bool active, string category);
public record LargeResponse(List<LargeItem> items, int count, int totalSize);
public record EchoResponse(EchoRequest? received, DateTime timestamp);
public record EchoRequest(string? message, int? value);
public record ComputeResponse(int result, DateTime timestamp);
public record MemoryResponse(int arraySize, int sum, DateTime timestamp);
public record PingResponse(string message);

[JsonSerializable(typeof(Amazon.Lambda.APIGatewayEvents.APIGatewayHttpApiV2ProxyRequest))]
[JsonSerializable(typeof(Amazon.Lambda.APIGatewayEvents.APIGatewayHttpApiV2ProxyResponse))]
[JsonSerializable(typeof(HealthResponse))]
[JsonSerializable(typeof(MinimalResponse))]
[JsonSerializable(typeof(SmallResponse))]
[JsonSerializable(typeof(MediumResponse))]
[JsonSerializable(typeof(MediumItem))]
[JsonSerializable(typeof(LargeResponse))]
[JsonSerializable(typeof(LargeItem))]
[JsonSerializable(typeof(EchoResponse))]
[JsonSerializable(typeof(EchoRequest))]
[JsonSerializable(typeof(ComputeResponse))]
[JsonSerializable(typeof(MemoryResponse))]
[JsonSerializable(typeof(PingResponse))]
public partial class LambdaApiJsonSerializerContext : JsonSerializerContext
{
}