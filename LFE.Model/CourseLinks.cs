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
    
    public partial class CourseLinks
    {
        public int Id { get; set; }
        public int CourseId { get; set; }
        public string Title { get; set; }
        public string LinkText { get; set; }
        public string LinkHref { get; set; }
        public string LinkImageUrl { get; set; }
        public int Ordinal { get; set; }
    
        public virtual Courses Courses { get; set; }
    }
}
