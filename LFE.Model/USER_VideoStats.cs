//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace LFE.Model
{
    using System;
    using System.Collections.Generic;
    
    public partial class USER_VideoStats
    {
        public long RowId { get; set; }
        public int UserId { get; set; }
        public long BcIdentifier { get; set; }
        public System.Guid SessionId { get; set; }
        public Nullable<int> ChapterId { get; set; }
        public System.DateTime StartDate { get; set; }
        public decimal StartPosition { get; set; }
        public Nullable<System.DateTime> EndDate { get; set; }
        public Nullable<decimal> EndPosition { get; set; }
        public Nullable<decimal> TotalSeconds { get; set; }
        public string EndReason { get; set; }
        public string StartReason { get; set; }
    
        public virtual CourseChapters CourseChapters { get; set; }
        public virtual Users Users { get; set; }
    }
}