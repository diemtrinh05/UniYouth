using System.Threading.Channels;
using System.Collections.Concurrent;

namespace UniYouth.Api.Application.Jobs
{
    public interface IAttendancePointsSyncQueue
    {
        bool Enqueue(int eventId);
        ValueTask<int> DequeueAsync(CancellationToken cancellationToken);
        bool TryMarkDone(int eventId);
    }

    /// <summary>
    /// In-memory queue cho job đồng bộ điểm attendance theo EventID.
    /// - Dedupe: 1 EventID chỉ có 1 job pending tại một thời điểm.
    /// - Phù hợp chạy 1 instance. Nếu scale-out nhiều instance, cần distributed queue/lock.
    /// </summary>
    public class AttendancePointsSyncQueue : IAttendancePointsSyncQueue
    {
        private readonly Channel<int> _channel;
        private readonly ConcurrentDictionary<int, byte> _pending = new();

        public AttendancePointsSyncQueue()
        {
            _channel = Channel.CreateUnbounded<int>(new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });
        }

        public bool Enqueue(int eventId)
        {
            if (eventId <= 0) return false;

            if (!_pending.TryAdd(eventId, 0))
            {
                return false; // already pending
            }

            // Unbounded channel: TryWrite should succeed.
            if (!_channel.Writer.TryWrite(eventId))
            {
                _pending.TryRemove(eventId, out _);
                return false;
            }

            return true;
        }

        public ValueTask<int> DequeueAsync(CancellationToken cancellationToken)
            => _channel.Reader.ReadAsync(cancellationToken);

        public bool TryMarkDone(int eventId)
            => _pending.TryRemove(eventId, out _);
    }
}
